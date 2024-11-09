module vfs

import os
import json
import time { now }

// VFS represents the virtual filesystem
pub struct VFS {
pub mut:
	root_id u32        // ID of root directory
	block_size u32 = 1024*4    // Size of data blocks in bytes
	root Directory     // Root directory
	data_dir string    // Directory to store VFS data
}

// Factory method for creating a new VFS instance
pub fn new(data_dir string) !VFS {
	if !os.exists(data_dir) {
		os.mkdir(data_dir) or { return error('Failed to create data directory: ${err}') }
	}

	mut filesystem := VFS{
		root_id: 1
		block_size: 1024*4
		data_dir: data_dir
	}

	current_time := now().unix()

	// Initialize root directory
	filesystem.root = Directory{
		metadata: Metadata{
			id: filesystem.root_id
			name: '/'
			file_type: .directory
			created_at: current_time
			modified_at: current_time
			accessed_at: current_time
			mode: 0o755
			owner: 'root'
			group: 'root'
		}
		parent_id: 0
		children: []FSEntry{}
	}

	// Try to load existing data
	filesystem.load() or {
		// If loading fails, save initial state
		filesystem.save() or { return error('Failed to save initial state: ${err}') }
	}

	return filesystem
}

// save persists the VFS state to disk
pub fn (mut filesystem VFS) save() ! {
	// Convert VFS state to JSON
	state := json.encode(filesystem)
	
	// Save to file
	os.write_file('${filesystem.data_dir}/vfs_state.json', state) or {
		return error('Failed to write VFS state: ${err}')
	}
}

// load restores the VFS state from disk
pub fn (mut filesystem VFS) load() ! {
	state_file := '${filesystem.data_dir}/vfs_state.json'
	if !os.exists(state_file) {
		return error('No saved state found')
	}

	// Read state file
	state := os.read_file(state_file) or {
		return error('Failed to read VFS state: ${err}')
	}

	// Parse JSON into VFS struct
	json.decode(VFS, state) or {
		return error('Failed to decode VFS state: ${err}')
	}
}

// get_root returns the root directory
pub fn (mut filesystem VFS) get_root() &Directory {
	return &filesystem.root
}
