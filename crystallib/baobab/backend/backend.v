module backend

import os
import db.sqlite
import db.pg
import freeflowuniverse.crystallib.core.dbfs
import freeflowuniverse.crystallib.data.encoderhero

pub struct Backend {
pub mut:
	indexer Indexer // storing indeces
	identifier Identifier
	dbs     dbfs.DBCollection // 
}

@[params]
pub struct BackendConfig {
pub:
	name   string
	secret string
	reset bool
	db_type DatabaseType
	identifier Identifier
	indexer Indexer
}

// fn get_db(name string, db_type DatabaseType) ! {
// 	match db_type {
// 		.sqlite {
// 			return sqlite.connect('${os.home_dir()}/hero/db/${name}.sqlite')!
// 		} .postgres {
// 			return pg.connect(dbname: name)!
// 		}
// 	}
// }

pub fn new(config BackendConfig) !Backend {
	mut backend := Backend{
		indexer: config.indexer
		// new_indexer(
		// 	Database{
		// 		sqlite_db: sqlite.connect('${os.home_dir()}/hero/db/${config.name}.sqlite')!
		// 	},
		// 	reset: config.reset
		// )!,
		identifier: config.identifier
		dbs: dbfs.get(
			contextid: 1
			secret: config.secret
		)!
	}
	if config.reset {
		backend.reset_all()!
	}

	backend.identifier.init()!
	return backend
}

pub fn (mut backend Backend) generic_new[T](obj_ T) !u32 {
	mut obj := obj_
	// mut db := backend.dbs.db_get_create(name: generic_get_table_name[T]()) or {
	// 	return error('Failed to get database for object <${T.name}>\n${err}')
	// }

	id := backend.identifier.new_id(typeof[T]())!
	backend.indexer.generic_new[T](obj)!
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

pub fn (mut backend Backend) generic_set[T](obj T) ! {
	mut db := backend.dbs.db_get_create(name: generic_get_table_name[T]()) or {
		return error('Failed to get database for object <${T.name}>\n${err}')
	}
	backend.indexer.generic_set[T](obj) or { return error('Failed to set new indices:\n${err}') }
	data := encoderhero.encode[T](obj)!
	// TODO: see if data changed
	db.set(id: obj.id, value: data)!
}

pub fn (mut backend Backend) generic_delete[T](id u32) ! {
	backend.indexer.generic_delete[T](id)!
	mut db := backend.dbs.db_get_create(name: generic_get_table_name[T]())!
	db.delete(id: id)!
}

pub fn (mut backend Backend) generic_get[T](id u32) !T {
	mut db := backend.dbs.db_get_create(name: generic_get_table_name[T]())!
	data := db.get(id: id) or { return error('Failed to get ${T.name} object with id: ${id}') }
	if data == '' {
		return error('Failed to get ${T.name} object with id: ${id}')
	}
	return encoderhero.decode[T](data)!
}

pub fn (mut backend Backend) generic_list[T]() ![]T {
	mut db := backend.dbs.db_get_create(name: generic_get_table_name[T]())!
	ids := db.ids()!
	datas := ids.map(db.get(id: it)!)
	mut results := []T{}
	// TODO: report v compiler bug with stmt below
	// results = datas.map(encoderhero.decode[T](it)!)
	for data in datas {
		results << encoderhero.decode[T](data)!
	}
	return results
}

pub fn (mut backend Backend) filter[T, D](filter D, params FilterParams) ![]T {
	mut db := backend.dbs.db_get_create(name: generic_get_table_name[T]())!
	ids := backend.indexer.filter[T, D](filter, params)!
	datas := ids.map(db.get(id: it)!)
	return datas.map(encoderhero.decode[T](it)!)
}

pub fn (mut backend Backend) reset[T]() ! {
	mut db := backend.dbs.db_get_create(name: generic_get_table_name[T]())!
	db.destroy()!
}

pub fn (mut backend Backend) reset_all() ! {
	backend.dbs.destroy()!
}
