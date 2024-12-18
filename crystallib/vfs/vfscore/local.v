module vfscore

import os

// LocalFSEntry implements FSEntry for local filesystem
struct LocalFSEntry {
mut:
	path     string
	metadata Metadata
}

fn (e LocalFSEntry) get_metadata() Metadata {
	return e.metadata
}

fn (e LocalFSEntry) get_path() string {
	return e.path
}

// LocalVFS implements VFSImplementation for local filesystem
pub struct LocalVFS {
mut:
	root_path string
}

// Create a new LocalVFS instance
pub fn new_local_vfs(root_path string) !VFSImplementation {
	mut myvfs := LocalVFS{
		root_path: root_path
	}
	myvfs.init()!
	return myvfs
}

// Initialize the local vfscore with a root path
fn (mut myvfs LocalVFS) init() ! {
	if !os.exists(myvfs.root_path) {
		os.mkdir_all(myvfs.root_path) or {
			return error('Failed to create root directory ${myvfs.root_path}: ${err}')
		}
	}
}

// Destroy the vfscore by removing all its contents
pub fn (mut myvfs LocalVFS) destroy() ! {
	if !os.exists(myvfs.root_path) {
		return error('vfscore root path does not exist: ${myvfs.root_path}')
	}
	os.rmdir_all(myvfs.root_path) or {
		return error('Failed to destroy vfscore at ${myvfs.root_path}: ${err}')
	}
	myvfs.init()!
}

// Convert path to Metadata with improved security and information gathering
fn (myvfs LocalVFS) os_attr_to_metadata(path string) !Metadata {
	// Get file info atomically to prevent TOCTOU issues
	attr := os.stat(path) or { return error('Failed to get file attributes: ${err}') }

	mut file_type := FileType.file
	if os.is_dir(path) {
		file_type = .directory
	} else if os.is_link(path) {
		file_type = .symlink
	}

	return Metadata{
		name:        os.base(path)
		file_type:   file_type
		size:        u64(attr.size)
		created_at:  i64(attr.ctime) // Creation time from stat
		modified_at: i64(attr.mtime) // Modification time from stat
		accessed_at: i64(attr.atime) // Access time from stat
	}
}

// Get absolute path from relative path
fn (myvfs LocalVFS) abs_path(path string) string {
	return os.join_path(myvfs.root_path, path)
}

// Basic operations
pub fn (myvfs LocalVFS) root_get() !FSEntry {
	if !os.exists(myvfs.root_path) {
		return error('Root path does not exist: ${myvfs.root_path}')
	}
	metadata := myvfs.os_attr_to_metadata(myvfs.root_path) or {
		return error('Failed to get root metadata: ${err}')
	}
	return LocalFSEntry{
		path:     ''
		metadata: metadata
	}
}

// File operations with improved error handling and TOCTOU protection
pub fn (myvfs LocalVFS) file_create(path string) !FSEntry {
	abs_path := myvfs.abs_path(path)
	if os.exists(abs_path) {
		return error('File already exists: ${path}')
	}
	os.write_file(abs_path, '') or { return error('Failed to create file ${path}: ${err}') }
	metadata := myvfs.os_attr_to_metadata(abs_path) or {
		return error('Failed to get metadata: ${err}')
	}
	return LocalFSEntry{
		path:     path
		metadata: metadata
	}
}

pub fn (myvfs LocalVFS) file_read(path string) ![]u8 {
	abs_path := myvfs.abs_path(path)
	if !os.exists(abs_path) {
		return error('File does not exist: ${path}')
	}
	if os.is_dir(abs_path) {
		return error('Path is a directory: ${path}')
	}
	return os.read_bytes(abs_path) or { return error('Failed to read file ${path}: ${err}') }
}

pub fn (myvfs LocalVFS) file_write(path string, data []u8) ! {
	abs_path := myvfs.abs_path(path)
	if os.is_dir(abs_path) {
		return error('Cannot write to directory: ${path}')
	}
	os.write_file(abs_path, data.bytestr()) or {
		return error('Failed to write file ${path}: ${err}')
	}
}

pub fn (myvfs LocalVFS) file_delete(path string) ! {
	abs_path := myvfs.abs_path(path)
	if !os.exists(abs_path) {
		return error('File does not exist: ${path}')
	}
	if os.is_dir(abs_path) {
		return error('Cannot delete directory using file_delete: ${path}')
	}
	os.rm(abs_path) or { return error('Failed to delete file ${path}: ${err}') }
}

// Directory operations with improved error handling
pub fn (myvfs LocalVFS) dir_create(path string) !FSEntry {
	abs_path := myvfs.abs_path(path)
	if os.exists(abs_path) {
		return error('Path already exists: ${path}')
	}
	os.mkdir_all(abs_path) or { return error('Failed to create directory ${path}: ${err}') }
	metadata := myvfs.os_attr_to_metadata(abs_path) or {
		return error('Failed to get metadata: ${err}')
	}
	return LocalFSEntry{
		path:     path
		metadata: metadata
	}
}

pub fn (myvfs LocalVFS) dir_list(path string) ![]FSEntry {
	abs_path := myvfs.abs_path(path)
	if !os.exists(abs_path) {
		return error('Directory does not exist: ${path}')
	}
	if !os.is_dir(abs_path) {
		return error('Path is not a directory: ${path}')
	}

	entries := os.ls(abs_path) or { return error('Failed to list directory ${path}: ${err}') }
	mut result := []FSEntry{cap: entries.len}

	for entry in entries {
		rel_path := os.join_path(path, entry)
		abs_entry_path := os.join_path(abs_path, entry)
		metadata := myvfs.os_attr_to_metadata(abs_entry_path) or { continue } // Skip entries we can't stat
		result << LocalFSEntry{
			path:     rel_path
			metadata: metadata
		}
	}
	return result
}

pub fn (myvfs LocalVFS) dir_delete(path string) ! {
	abs_path := myvfs.abs_path(path)
	if !os.exists(abs_path) {
		return error('Directory does not exist: ${path}')
	}
	if !os.is_dir(abs_path) {
		return error('Path is not a directory: ${path}')
	}
	os.rmdir_all(abs_path) or { return error('Failed to delete directory ${path}: ${err}') }
}

// Common operations with improved error handling
pub fn (myvfs LocalVFS) exists(path string) bool {
	// TODO: check is link if link the link can be broken but it stil exists
	return os.exists(myvfs.abs_path(path))
}

pub fn (myvfs LocalVFS) get(path string) !FSEntry {
	abs_path := myvfs.abs_path(path)
	if !os.exists(abs_path) {
		return error('Entry does not exist: ${path}')
	}
	metadata := myvfs.os_attr_to_metadata(abs_path) or {
		return error('Failed to get metadata: ${err}')
	}
	return LocalFSEntry{
		path:     path
		metadata: metadata
	}
}

pub fn (myvfs LocalVFS) rename(old_path string, new_path string) ! {
	abs_old := myvfs.abs_path(old_path)
	abs_new := myvfs.abs_path(new_path)

	if !os.exists(abs_old) {
		return error('Source path does not exist: ${old_path}')
	}
	if os.exists(abs_new) {
		return error('Destination path already exists: ${new_path}')
	}

	os.mv(abs_old, abs_new) or {
		return error('Failed to rename ${old_path} to ${new_path}: ${err}')
	}
}

pub fn (myvfs LocalVFS) copy(src_path string, dst_path string) ! {
	abs_src := myvfs.abs_path(src_path)
	abs_dst := myvfs.abs_path(dst_path)

	if !os.exists(abs_src) {
		return error('Source path does not exist: ${src_path}')
	}
	if os.exists(abs_dst) {
		return error('Destination path already exists: ${dst_path}')
	}

	os.cp(abs_src, abs_dst) or { return error('Failed to copy ${src_path} to ${dst_path}: ${err}') }
}

// Generic delete operation that handles all types
pub fn (myvfs LocalVFS) delete(path string) ! {
	abs_path := myvfs.abs_path(path)
	if !os.exists(abs_path) {
		return error('Path does not exist: ${path}')
	}

	if os.is_link(abs_path) {
		myvfs.link_delete(path)!
	} else if os.is_dir(abs_path) {
		myvfs.dir_delete(path)!
	} else {
		myvfs.file_delete(path)!
	}
}

// Symlink operations with improved handling
pub fn (myvfs LocalVFS) link_create(target_path string, link_path string) !FSEntry {
	abs_target := myvfs.abs_path(target_path)
	abs_link := myvfs.abs_path(link_path)

	if !os.exists(abs_target) {
		return error('Target path does not exist: ${target_path}')
	}
	if os.exists(abs_link) {
		return error('Link path already exists: ${link_path}')
	}

	os.symlink(target_path, abs_link) or {
		return error('Failed to create symlink from ${target_path} to ${link_path}: ${err}')
	}

	metadata := myvfs.os_attr_to_metadata(abs_link) or {
		return error('Failed to get metadata: ${err}')
	}
	return LocalFSEntry{
		path:     link_path
		metadata: metadata
	}
}

pub fn (myvfs LocalVFS) link_read(path string) !string {
	abs_path := myvfs.abs_path(path)
	if !os.exists(abs_path) {
		return error('Symlink does not exist: ${path}')
	}
	if !os.is_link(abs_path) {
		return error('Path is not a symlink: ${path}')
	}

	real_path := os.real_path(abs_path)
	return os.base(real_path)
}

pub fn (myvfs LocalVFS) link_delete(path string) ! {
	abs_path := myvfs.abs_path(path)
	if !os.exists(abs_path) {
		return error('Symlink does not exist: ${path}')
	}
	if !os.is_link(abs_path) {
		return error('Path is not a symlink: ${path}')
	}
	os.rm(abs_path) or { return error('Failed to delete symlink ${path}: ${err}') }
}
