module osis

import freeflowuniverse.crystallib.data.dbfs
import db.sqlite
import os

pub struct Storer {
pub:
	directory string
	db_filesystem dbfs.DBCollection
	db_sqlite sqlite.DB
}

@[params]
pub struct StorerConfig {
	context_id u32
	secret string
	directory string = '${os.home_dir()}/hero/baobab/storer' // Directory of the storer
}

pub fn new_storer(config StorerConfig) !Storer {
	return Storer {
		directory: config.directory
		db_filesystem: dbfs.get(
			dbpath: '${config.directory}/dbfs/${config.context_id}'
			secret: config.secret
			contextid: config.context_id
		)!
	}
}

@[params]
pub struct StorageParams {
	// database_type DatabaseType
	encrypted bool
}

pub fn (mut storer Storer) new(object RootObject, params StorageParams) !u32 {
	panic('implement')
}

pub fn (mut storer Storer) get(id u32, params StorageParams) !RootObject {
	panic('implement')
}

pub fn (mut storer Storer) set(object RootObject, params StorageParams) ! {
	panic('implement')
}

pub fn (mut storer Storer) delete(id u32, params StorageParams) ! {
	panic('implement')
}

pub fn (mut storer Storer) list(ids []u32, params StorageParams) ![]RootObject {
	panic('implement')
}