module vfsourdb

import freeflowuniverse.crystallib.vfs.vfscore
import freeflowuniverse.crystallib.vfs.ourdb_fs
import os
import time

// OurDBVFS represents a VFS that uses OurDB as the underlying storage
pub struct OurDBVFS {
mut:
	core &ourdb_fs.VFS
}

// new creates a new OurDBVFS instance
pub fn new(data_dir string, metadata_dir string) !&OurDBVFS {
	mut core := ourdb_fs.new(
		data_dir:     data_dir
		metadata_dir: metadata_dir
	)!

	return &OurDBVFS{
		core: core
	}
}

// Implementation of VFSImplementation interface
pub fn (mut self OurDBVFS) root_get() !vfscore.FSEntry {
	mut root := self.core.get_root()!
	return convert_to_vfscore_entry(root)
}

pub fn (mut self OurDBVFS) file_create(path string) !vfscore.FSEntry {
	// Get parent directory
	parent_path := os.dir(path)
	file_name := os.base(path)

	mut parent_dir := self.get_directory(parent_path)!
	mut file := parent_dir.touch(file_name)!
	return convert_to_vfscore_entry(file)
}

pub fn (mut self OurDBVFS) file_read(path string) ![]u8 {
	mut entry := self.get_entry(path)!
	if mut entry is ourdb_fs.File {
		content := entry.read()!
		return content.bytes()
	}
	return error('Not a file: ${path}')
}

pub fn (mut self OurDBVFS) file_write(path string, data []u8) ! {
	mut entry := self.get_entry(path)!
	if mut entry is ourdb_fs.File {
		entry.write(data.bytestr())!
	} else {
		return error('Not a file: ${path}')
	}
}

pub fn (mut self OurDBVFS) file_delete(path string) ! {
	parent_path := os.dir(path)
	file_name := os.base(path)

	mut parent_dir := self.get_directory(parent_path)!
	parent_dir.rm(file_name)!
}

pub fn (mut self OurDBVFS) dir_create(path string) !vfscore.FSEntry {
	parent_path := os.dir(path)
	dir_name := os.base(path)

	mut parent_dir := self.get_directory(parent_path)!
	mut new_dir := parent_dir.mkdir(dir_name)!
	return convert_to_vfscore_entry(new_dir)
}

pub fn (mut self OurDBVFS) dir_list(path string) ![]vfscore.FSEntry {
	mut dir := self.get_directory(path)!
	mut entries := dir.children(false)!
	mut result := []vfscore.FSEntry{}

	for entry in entries {
		result << convert_to_vfscore_entry(entry)
	}

	return result
}

pub fn (mut self OurDBVFS) dir_delete(path string) ! {
	parent_path := os.dir(path)
	dir_name := os.base(path)

	mut parent_dir := self.get_directory(parent_path)!
	parent_dir.rm(dir_name)!
}

pub fn (mut self OurDBVFS) exists(path string) !bool {
	if path == '/' {
		return true
	}
	self.get_entry(path) or { return false }
	return true
}

pub fn (mut self OurDBVFS) get(path string) !vfscore.FSEntry {
	mut entry := self.get_entry(path)!
	return convert_to_vfscore_entry(entry)
}

pub fn (mut self OurDBVFS) rename(old_path string, new_path string) ! {
	return error('Not implemented')
}

pub fn (mut self OurDBVFS) copy(src_path string, dst_path string) ! {
	return error('Not implemented')
}

pub fn (mut self OurDBVFS) link_create(target_path string, link_path string) !vfscore.FSEntry {
	parent_path := os.dir(link_path)
	link_name := os.base(link_path)

	mut parent_dir := self.get_directory(parent_path)!

	mut symlink := ourdb_fs.Symlink{
		metadata:  ourdb_fs.Metadata{
			id:          u32(time.now().unix())
			name:        link_name
			file_type:   .symlink
			created_at:  time.now().unix()
			modified_at: time.now().unix()
			accessed_at: time.now().unix()
			mode:        0o777
			owner:       'user'
			group:       'user'
		}
		target:    target_path
		parent_id: parent_dir.metadata.id
		myvfs:     self.core
	}

	parent_dir.add_symlink(symlink)!
	return convert_to_vfscore_entry(symlink)
}

pub fn (mut self OurDBVFS) link_read(path string) !string {
	mut entry := self.get_entry(path)!
	if mut entry is ourdb_fs.Symlink {
		return entry.get_target()!
	}
	return error('Not a symlink: ${path}')
}

pub fn (mut self OurDBVFS) destroy() ! {
	// Nothing to do as the core VFS handles cleanup
}

// Helper functions

fn (mut self OurDBVFS) get_entry(path string) !ourdb_fs.FSEntry {
	if path == '/' {
		return self.core.get_root()!
	}

	mut current := self.core.get_root()!
	parts := path.trim_left('/').split('/')

	for i := 0; i < parts.len; i++ {
		found := false
		children := current.children(false)!

		for child in children {
			if child.metadata.name == parts[i] {
				match child {
					ourdb_fs.Directory {
						current = child
						found = true
						break
					}
					else {
						if i == parts.len - 1 {
							return child
						} else {
							return error('Not a directory: ${parts[i]}')
						}
					}
				}
			}
		}

		if !found {
			return error('Path not found: ${path}')
		}
	}

	return current
}

fn (mut self OurDBVFS) get_directory(path string) !&ourdb_fs.Directory {
	mut entry := self.get_entry(path)!
	if mut entry is ourdb_fs.Directory {
		return &entry
	}
	return error('Not a directory: ${path}')
}

fn convert_to_vfscore_entry(entry ourdb_fs.FSEntry) vfscore.FSEntry {
	match entry {
		ourdb_fs.Directory {
			return &DirectoryEntry{
				metadata: convert_metadata(entry.metadata)
				path:     entry.metadata.name
			}
		}
		ourdb_fs.File {
			return &FileEntry{
				metadata: convert_metadata(entry.metadata)
				path:     entry.metadata.name
			}
		}
		ourdb_fs.Symlink {
			return &SymlinkEntry{
				metadata: convert_metadata(entry.metadata)
				path:     entry.metadata.name
				target:   entry.target
			}
		}
	}
}

fn convert_metadata(meta ourdb_fs.Metadata) vfscore.Metadata {
	return vfscore.Metadata{
		name:        meta.name
		file_type:   match meta.file_type {
			.file { vfscore.FileType.file }
			.directory { vfscore.FileType.directory }
			.symlink { vfscore.FileType.symlink }
		}
		size:        meta.size
		created_at:  meta.created_at
		modified_at: meta.modified_at
		accessed_at: meta.accessed_at
	}
}

// Entry type implementations
struct DirectoryEntry {
	metadata vfscore.Metadata
	path     string
}

fn (e &DirectoryEntry) get_metadata() vfscore.Metadata {
	return e.metadata
}

fn (e &DirectoryEntry) get_path() string {
	return e.path
}

struct FileEntry {
	metadata vfscore.Metadata
	path     string
}

fn (e &FileEntry) get_metadata() vfscore.Metadata {
	return e.metadata
}

fn (e &FileEntry) get_path() string {
	return e.path
}

struct SymlinkEntry {
	metadata vfscore.Metadata
	path     string
	target   string
}

fn (e &SymlinkEntry) get_metadata() vfscore.Metadata {
	return e.metadata
}

fn (e &SymlinkEntry) get_path() string {
	return e.path
}
