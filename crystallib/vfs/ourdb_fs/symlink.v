module ourdb_fs

import time

// Symlink represents a symbolic link in the virtual filesystem
pub struct Symlink {
pub mut:
	metadata  Metadata // Metadata from models_common.v
	target    string   // Path that this symlink points to
	parent_id u32      // ID of parent directory
	myvfs     &OurDBFS @[skip]
}

pub fn (mut sl Symlink) save() ! {
	sl.myvfs.save_entry(sl)!
}

// update_target changes the symlink's target path
pub fn (mut sl Symlink) update_target(new_target string) ! {
	sl.target = new_target
	sl.metadata.modified_at = time.now().unix()

	// Save updated symlink to DB
	sl.save() or { return error('Failed to update symlink target: ${err}') }
}

// get_target returns the current target path
pub fn (mut sl Symlink) get_target() !string {
	sl.metadata.accessed_at = time.now().unix()

	// Update access time in DB
	sl.save() or { return error('Failed to update symlink access time: ${err}') }

	return sl.target
}
