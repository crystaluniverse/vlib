module ourdb_fs

import time

// FileType represents the type of a filesystem entry
pub enum FileType {
	file
	directory
	symlink
}

// Metadata represents the common metadata for both files and directories
pub struct Metadata {
pub mut:
	id          u32    // unique identifier used as key in DB
	name        string // name of file or directory
	file_type   FileType
	size        u64
	created_at  i64 // unix epoch timestamp
	modified_at i64 // unix epoch timestamp
	accessed_at i64 // unix epoch timestamp
	mode        u32 // file permissions
	owner       string
	group       string
}

// Get time.Time objects from epochs
pub fn (m Metadata) created_time() time.Time {
	return time.unix(m.created_at)
}

pub fn (m Metadata) modified_time() time.Time {
	return time.unix(m.modified_at)
}

pub fn (m Metadata) accessed_time() time.Time {
	return time.unix(m.accessed_at)
}
