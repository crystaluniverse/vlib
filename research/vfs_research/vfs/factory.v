module vfs

import os
import time { now }
import freeflowuniverse.crystallib.data.ourdb


// Factory method for creating a new VFS instance
@[params]
pub struct VFSParams {
pub:
	data_dir string     // Directory to store VFS data
	metadata_dir string // Directory to store VFS metadata
}

// Factory method for creating a new VFS instance
pub fn new(params VFSParams) !&VFS {
	if !os.exists(params.data_dir) {
		os.mkdir(params.data_dir) or { return error('Failed to create data directory: ${err}') }
	}
	if !os.exists(params.metadata_dir) {
		os.mkdir(params.metadata_dir) or { return error('Failed to create metadata directory: ${err}') }
	}

	mut db_meta := ourdb.new(path: '${params.metadata_dir}/vfs.db_meta')!
	mut db_data := ourdb.new(path: '${params.data_dir}/vfs_metadata.db_meta')!

	mut fs := &VFS{
		root_id: 1
		block_size: 1024 * 4
		data_dir: params.data_dir
		metadata_dir: params.metadata_dir
		db_meta: &db_meta
		db_data: &db_data
	}

	return fs
}
