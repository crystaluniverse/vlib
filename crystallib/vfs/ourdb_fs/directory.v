module ourdb_fs

import time

// FSEntry represents any type of filesystem entry
pub type FSEntry = Directory | File | Symlink

// Directory represents a directory in the virtual filesystem
pub struct Directory {
pub mut:
	metadata  Metadata // Metadata from models_common.v
	children  []u32    // List of child entry IDs (instead of actual entries)
	parent_id u32      // ID of parent directory (0 for root)
	myvfs     &OurDBFS @[skip]
}

pub fn (mut self Directory) save() ! {
	self.myvfs.save_entry(self)!
}

// write creates a new file or writes to an existing file
pub fn (mut dir Directory) write(name string, content string) !&File {
	mut file := &File{
		myvfs: dir.myvfs
	}
	mut is_new := true

	// Check if file exists
	for child_id in dir.children {
		mut entry := dir.myvfs.load_entry(child_id)!
		if entry.metadata.name == name {
			if mut entry is File {
				mut d := entry
				file = &d
				is_new = false
				break
			} else {
				return error('${name} exists but is not a file')
			}
		}
	}

	if is_new {
		// Create new file
		current_time := time.now().unix()
		file = &File{
			metadata:  Metadata{
				id:          u32(time.now().unix())
				name:        name
				file_type:   .file
				size:        u64(content.len)
				created_at:  current_time
				modified_at: current_time
				accessed_at: current_time
				mode:        0o644
				owner:       'user'
				group:       'user'
			}
			data:      content
			parent_id: dir.metadata.id
			myvfs:     dir.myvfs
		}

		// Save new file to DB
		dir.myvfs.save_entry(file)!

		// Update children list
		dir.children << file.metadata.id
		dir.myvfs.save_entry(dir)!
	} else {
		// Update existing file
		file.write(content)!
	}

	return file
}

// read reads content from a file
pub fn (mut dir Directory) read(name string) !string {
	// Find file
	for child_id in dir.children {
		if mut entry := dir.myvfs.load_entry(child_id) {
			if entry.metadata.name == name {
				if mut entry is File {
					return entry.read()
				} else {
					return error('${name} is not a file')
				}
			}
		}
	}
	return error('File ${name} not found')
}

// str returns a formatted string of directory contents (non-recursive)
pub fn (mut dir Directory) str() string {
	mut result := '${dir.metadata.name}/\n'

	for child_id in dir.children {
		if entry := dir.myvfs.load_entry(child_id) {
			if entry is Directory {
				result += '  📁 ${entry.metadata.name}/\n'
			} else if entry is File {
				result += '  📄 ${entry.metadata.name}\n'
			} else if entry is Symlink {
				result += '  🔗 ${entry.metadata.name} -> ${entry.target}\n'
			}
		}
	}
	return result
}

// printall prints the directory structure recursively
pub fn (mut dir Directory) printall(indent string) !string {
	mut result := '${indent}📁 ${dir.metadata.name}/\n'

	for child_id in dir.children {
		mut entry := dir.myvfs.load_entry(child_id)!
		if mut entry is Directory {
			result += entry.printall(indent + '  ')!
		} else if entry is File {
			result += '${indent}  📄 ${entry.metadata.name}\n'
		} else if mut entry is Symlink {
			result += '${indent}  🔗 ${entry.metadata.name} -> ${entry.target}\n'
		}
	}
	return result
}

// mkdir creates a new directory with default permissions
pub fn (mut dir Directory) mkdir(name string) !&Directory {
	// Check if directory already exists
	for child_id in dir.children {
		if entry := dir.myvfs.load_entry(child_id) {
			if entry.metadata.name == name {
				return error('Directory ${name} already exists')
			}
		}
	}

	current_time := time.now().unix()
	mut new_dir := Directory{
		metadata:  Metadata{
			id:          u32(time.now().unix()) // Use timestamp as ID
			name:        name
			file_type:   .directory
			created_at:  current_time
			modified_at: current_time
			accessed_at: current_time
			mode:        0o755  // default directory permissions
			owner:       'user' // TODO: get from system
			group:       'user' // TODO: get from system
		}
		children:  []u32{}
		parent_id: dir.metadata.id
		myvfs:     dir.myvfs
	}

	// Save new directory to DB
	dir.myvfs.save_entry(new_dir)!

	// Update children list
	dir.children << new_dir.metadata.id
	dir.myvfs.save_entry(dir)!

	return &new_dir
}

// touch creates a new empty file with default permissions
pub fn (mut dir Directory) touch(name string) !&File {
	// Check if file already exists
	for child_id in dir.children {
		if entry := dir.myvfs.load_entry(child_id) {
			if entry.metadata.name == name {
				return error('File ${name} already exists')
			}
		}
	}

	current_time := time.now().unix()
	mut new_file := File{
		metadata:  Metadata{
			name:        name
			file_type:   .file
			size:        0
			created_at:  current_time
			modified_at: current_time
			accessed_at: current_time
			mode:        0o644  // default file permissions
			owner:       'user' // TODO: get from system
			group:       'user' // TODO: get from system
		}
		data:      '' // Initialize with empty content
		parent_id: dir.metadata.id
		myvfs:     dir.myvfs
	}

	// Save new file to DB
	new_file.metadata.id = dir.myvfs.save_entry(new_file)!

	// Update children list
	dir.children << new_file.metadata.id
	dir.myvfs.save_entry(dir)!

	return &new_file
}

// rm removes a file or directory by name
pub fn (mut dir Directory) rm(name string) ! {
	mut found := false
	mut found_id := u32(0)
	mut found_idx := 0

	for i, child_id in dir.children {
		if entry := dir.myvfs.load_entry(child_id) {
			if entry.metadata.name == name {
				found = true
				found_id = child_id
				found_idx = i
				if entry is Directory {
					if entry.children.len > 0 {
						return error('Directory not empty')
					}
				}
				break
			}
		}
	}

	if !found {
		return error('${name} not found')
	}

	// Delete entry from DB
	dir.myvfs.delete_entry(found_id)!

	// Update children list
	dir.children.delete(found_idx)
	dir.myvfs.save_entry(dir)!
}

// get_children returns all immediate children as FSEntry objects
pub fn (mut dir Directory) children(recursive bool) ![]FSEntry {
	mut entries := []FSEntry{}

	for child_id in dir.children {
		entry := dir.myvfs.load_entry(child_id)!
		entries << entry
		if recursive {
			if entry is Directory {
				mut d := entry
				entries << d.children(true)!
			}
		}
	}

	return entries
}

pub fn (mut dir Directory) delete() {
	// Delete all children first
	for child_id in dir.children {
		dir.myvfs.delete_entry(child_id) or {}
	}

	// Clear children list
	dir.children.clear()

	// Save the updated directory
	dir.myvfs.save_entry(dir) or {}
}

// add_symlink adds an existing symlink to this directory
pub fn (mut dir Directory) add_symlink(symlink Symlink) ! {
	// Check if name already exists
	for child_id in dir.children {
		if entry := dir.myvfs.load_entry(child_id) {
			if entry.metadata.name == symlink.metadata.name {
				return error('Entry with name ${symlink.metadata.name} already exists')
			}
		}
	}

	// Save symlink to DB
	dir.myvfs.save_entry(symlink)!

	// Add to children
	dir.children << symlink.metadata.id
	dir.myvfs.save_entry(dir)!
}
