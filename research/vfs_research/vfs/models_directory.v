module vfs

import time { now }

// FSEntry represents any type of filesystem entry
pub type FSEntry = Directory | File | Symlink

// Directory represents a directory in the virtual filesystem
pub struct Directory {
pub mut:
	metadata Metadata  // Metadata from models_common.v
	parent_id u32     // ID of parent directory
	children []FSEntry // List of child entries (files and directories)
}

// str returns a formatted string of directory contents (non-recursive)
pub fn (dir Directory) str() string {
	mut result := '${dir.metadata.name}/\n'
	for child in dir.children {
		match child {
			Directory {
				result += '  📁 ${child.metadata.name}/\n'
			}
			File {
				result += '  📄 ${child.metadata.name}\n'
			}
			Symlink {
				result += '  🔗 ${child.metadata.name} -> ${child.target}\n'
			}
		}
	}
	return result
}

// printall prints the directory structure recursively
pub fn (dir Directory) printall(indent string) string {
	mut result := '${indent}📁 ${dir.metadata.name}/\n'
	for child in dir.children {
		match child {
			Directory {
				result += child.printall(indent + '  ')
			}
			File {
				result += '${indent}  📄 ${child.metadata.name}\n'
			}
			Symlink {
				result += '${indent}  🔗 ${child.metadata.name} -> ${child.target}\n'
			}
		}
	}
	return result
}

// Directory methods

// mkdir creates a new directory with default permissions
pub fn (mut dir Directory) mkdir(name string) !&Directory {
	// Check if directory already exists
	for child in dir.children {
		if child.metadata.name == name {
			return error('Directory ${name} already exists')
		}
	}

	current_time := now().unix()
	mut new_dir := Directory{
		metadata: Metadata{
			id: dir.get_next_id()
			name: name
			file_type: .directory
			created_at: current_time
			modified_at: current_time
			accessed_at: current_time
			mode: 0o755  // default directory permissions
			owner: 'user'  // TODO: get from system
			group: 'user'  // TODO: get from system
		}
		parent_id: dir.metadata.id
		children: []FSEntry{}
	}

	dir.children << new_dir
	return &new_dir
}

// touch creates a new empty file with default permissions
pub fn (mut dir Directory) touch(name string) !&File {
	// Check if file already exists
	for child in dir.children {
		if child.metadata.name == name {
			return error('File ${name} already exists')
		}
	}

	current_time := now().unix()
	mut new_file := File{
		metadata: Metadata{
			id: dir.get_next_id()
			name: name
			file_type: .file
			size: 0
			created_at: current_time
			modified_at: current_time
			accessed_at: current_time
			mode: 0o644  // default file permissions
			owner: 'user'  // TODO: get from system
			group: 'user'  // TODO: get from system
		}
		parent_id: dir.metadata.id
		data: ''  // Initialize with empty content
	}

	dir.children << new_file
	return &new_file
}

// rm removes a file or directory by name
pub fn (mut dir Directory) rm(name string) ! {
	mut found := false
	for i, child in dir.children {
		if child.metadata.name == name {
			found = true
			match child {
				Directory {
					if child.children.len > 0 {
						return error('Directory not empty')
					}
				}
				File, Symlink {
					// No special handling needed
				}
			}
			dir.children.delete(i)
			break
		}
	}
	if !found {
		return error('${name} not found')
	}
}

// write writes data to a file
pub fn (mut dir Directory) write(name string, data string) ! {
	for i, mut child in dir.children {
		if child.metadata.name == name {
			match mut child {
				File {
					child.data = data
					child.metadata.size = u64(data.len)
					child.metadata.modified_at = now().unix()
					dir.children[i] = child
					return
				}
				else {
					return error('${name} is not a file')
				}
			}
		}
	}
	return error('File ${name} not found')
}

// read reads data from a file
pub fn (mut dir Directory) read(name string) !string {
	for mut child in dir.children {
		if child.metadata.name == name {
			match mut child {
				File {
					child.metadata.accessed_at = now().unix()
					return child.data
				}
				else {
					return error('${name} is not a file')
				}
			}
		}
	}
	return error('File ${name} not found')
}

// list returns all children, optionally including descendants
pub fn (mut dir Directory) list(recursive bool) []FSEntry {
	if !recursive {
		return dir.children.clone()
	}
	
	mut all_children := []FSEntry{}
	all_children << dir.children
	
	// Recursively add children of subdirectories
	for mut child in dir.children {
		match mut child {
			Directory {
				all_children << child.list(true)
			}
			File, Symlink {
				// Skip non-directory entries
				continue
			}
		}
	}
	return all_children
}

// get_children returns all immediate children as FSEntry objects
pub fn (mut dir Directory) get_children(recursive bool) []FSEntry {
	if !recursive {
		return dir.children.clone()
	}
	
	mut entries := []FSEntry{}
	entries << dir.children
	
	// If recursive, add children of subdirectories
	for mut child in dir.children {
		match mut child {
			Directory {
				entries << child.get_children(true)
			}
			File, Symlink {
				continue
			}
		}
	}
	return entries
}

// get_next_id generates a new unique ID for entries
fn (dir Directory) get_next_id() u32 {
	return u32(now().unix())
}

pub fn (mut dir Directory) delete() {
	dir.children.clear()
}
