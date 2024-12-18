module ourdb_fs

import os
import freeflowuniverse.crystallib.data.ourdb

// Factory method for creating a new OurDBFS instance
@[params]
pub struct VFSParams {
pub:
	data_dir     string // Directory to store OurDBFS data
	metadata_dir string // Directory to store OurDBFS metadata
}

// Factory method for creating a new OurDBFS instance
pub fn new(params VFSParams) !&OurDBFS {
	if !os.exists(params.data_dir) {
		os.mkdir(params.data_dir) or { return error('Failed to create data directory: ${err}') }
	}
	if !os.exists(params.metadata_dir) {
		os.mkdir(params.metadata_dir) or {
			return error('Failed to create metadata directory: ${err}')
		}
	}

	mut db_meta := ourdb.new(path: '${params.metadata_dir}/ourdb_fs.db_meta')! // TODO: doesn't seem to be good names
	mut db_data := ourdb.new(path: '${params.data_dir}/vfs_metadata.db_meta')!

	mut fs := &OurDBFS{
		root_id:      1
		block_size:   1024 * 4
		data_dir:     params.data_dir
		metadata_dir: params.metadata_dir
		db_meta:      &db_meta
		db_data:      &db_data
	}

	return fs
}
