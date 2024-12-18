module ourdb_fs

import time

// File represents a file in the virtual filesystem
pub struct File {
pub mut:
	metadata  Metadata // Metadata from models_common.v
	data      string   // File content stored in DB
	parent_id u32      // ID of parent directory
	myvfs     &OurDBFS @[skip]
}

pub fn (mut f File) save() ! {
	f.myvfs.save_entry(f)!
}

// write updates the file's content
pub fn (mut f File) write(content string) ! {
	f.data = content
	f.metadata.size = u64(content.len)
	f.metadata.modified_at = time.now().unix()

	// Save updated file to DB
	f.save()!
}

// read returns the file's content
pub fn (mut f File) read() !string {
	return f.data
}
