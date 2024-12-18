module backend

import freeflowuniverse.crystallib.data.dbfs

pub struct Storer {
pub:
	directory string @[required]
	identifier DBIdentifier
	db_filesystem dbfs.DBCollection
	db_sqlite DBStorer
	default_database DatabaseType
}

@[params]
pub struct StorerConfig {
	context_id u32
	secret string
	directory string = '${os.home_dir()}/hero/baobab/storer' // Directory of the storer
	default_driver DBDriver
}

// pub enum DBDriver {
// 	@none
// 	filesystem
// 	relational
// }

pub fn new_storer(config StorerConfig) Storer {
	return Storer {
		directory: config.directory
		identifier: DBIdentifier{}
		filesystem: dbfs.get(
			dbpath: '${config.directory}/dbfs/${config.context_id}'
			secret: config.secret
			contextid: config.context_id
		)
	}
}

// @[params]
// pub struct StorageParams {
// 	database_type DatabaseType
// 	encrypted bool
// }

pub fn (mut storer Storer) new(data string, params StorageParams) !u32 {
	database_type := if params.database_type == @none {
		storer.default_database
	} else {
		params.database_type
	}

	// first store object 
	db_id := match database_type {
		.filesystem {
			db := storer.db_collection.db_get_create(name: 'default')!
			db.set(value: data)!
		}
		.postgres {

			obj := BaseObject{
				object: object
				db: db
			}
			id := sql i.db {
				insert obj into BaseObject
			} or {return err}
			return u32(id)	
		}
	} else if database_type == 
	}

	id := storer.identifier.new_id(
		db_id: 
		object: 
	)

	id := backend.identifier.new_id(typeof[T]())!
	backend.indexer.new(obj)!
	return id

	// $for field in T.fields {
	// 	if field.name == 'id' {
	// 		obj.id = id
	// 	}
	// 	else if field.name == 'Base' {
	// 		obj.id = id
	// 	}
	// }
	// data := encoderhero.encode[T](obj)!
	// obj.id = db.set(value: data) or { return error('Failed to set data ${err}') }
	// return db.set(id: obj.id, value: encoderhero.encode[T](obj)!)
}