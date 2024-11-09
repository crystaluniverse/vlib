module vfs

// File represents a file in the virtual filesystem
pub struct File {
pub mut:
	metadata Metadata  // Metadata from models_common.v
	parent_id u32     // ID of parent directory
	data string       // File content stored in memory
}

// File methods
pub fn (mut f File) delete() {
	f.data = ''      // Clear content
	f.metadata.size = 0
}
