module backend

import freeflowuniverse.crystallib.data.dbfs
import db.sqlite
import os

pub struct Storer {
pub:
	directory string
	identifier DBIdentifier
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
		identifier: DBIdentifier{}
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

pub fn (mut storer Storer) new(data string, params StorageParams) !u32 {
	panic('implement')
}