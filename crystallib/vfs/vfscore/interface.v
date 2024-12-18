module vfscore

// FileType represents the type of a filesystem entry
pub enum FileType {
	file
	directory
	symlink
}

// Metadata represents the common metadata for both files and directories
pub struct Metadata {
pub mut:
	name        string // name of file or directory
	file_type   FileType
	size        u64
	created_at  i64 // unix epoch timestamp
	modified_at i64 // unix epoch timestamp
	accessed_at i64 // unix epoch timestamp
}

// FSEntry represents a filesystem entry (file, directory, or symlink)
pub interface FSEntry {
	get_metadata() Metadata
	get_path() string
}

// VFSImplementation defines the interface that all vfscore implementations must follow
pub interface VFSImplementation {
mut:
	// Basic operations
	root_get() !FSEntry

	// File operations
	file_create(path string) !FSEntry
	file_read(path string) ![]u8
	file_write(path string, data []u8) !
	file_delete(path string) !

	// Directory operations
	dir_create(path string) !FSEntry
	dir_list(path string) ![]FSEntry
	dir_delete(path string) !

	// Common operations
	exists(path string) bool
	get(path string) !FSEntry
	rename(old_path string, new_path string) !
	copy(src_path string, dst_path string) !
	delete(path string) !

	// Symlink operations
	link_create(target_path string, link_path string) !FSEntry
	link_read(path string) !string
	link_delete(path string) !

	// Cleanup operation
	destroy() !
}
