module vfs

// Symlink represents a symbolic link in the virtual filesystem
pub struct Symlink {
pub mut:
	metadata Metadata  // Metadata from models_common.v
	parent_id u32     // ID of parent directory
	target string     // Path that this symlink points to
}

// Symlink methods
pub fn (mut sl Symlink) delete() {
	sl.target = ''   // Clear target path
}
