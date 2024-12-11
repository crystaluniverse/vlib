module osal

import freeflowuniverse.crystallib.core.base
import freeflowuniverse.crystallib.data.dbfs
import freeflowuniverse.crystallib.ui.console

fn donedb() !&dbfs.DB {
	mut context := base.context()!
	mut collection := context.dbcollection()!
	mut db := collection.db_get_create(name: 'todo', withkeys: true)!
	return &db
}

pub fn done_set(key string, val string) ! {
	mut db := donedb()!
	db.set(key: key, value: val)!
}

pub fn done_get(key string) ?string {
	mut db := donedb() or { panic(err) }
	return db.get(key: key) or { return none }
}

pub fn done_delete(key string) ! {
	mut db := donedb()!
	db.delete(key: key)!
}

pub fn done_get_str(key string) string {
	val := done_get(key) or { panic(err) }
	return val
}

pub fn done_get_int(key string) int {
	val := done_get(key) or { panic(err) }
	return val.int()
}

pub fn done_exists(key string) bool {
	mut db := donedb() or { panic(err) }
	return db.exists(key: key) or { false }
}

pub fn done_print() ! {
	mut db := donedb()!
	mut output := 'DONE:\n'
	for key in db.keys('')! {
		output += '\t${key} = ${done_get_str(key)}\n'
	}
	console.print_debug('${output}')
}

pub fn done_reset() ! {
	mut db := donedb()!
	db.destroy()!
}
