module osis

import json
import db.sqlite
import db.pg
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.clients.postgres
import orm

// new creates a new root object entry in the root_objects table,
// and the table belonging to the type of root object with columns for index fields
pub fn (mut storer Storer) generic_new[T](obj T) !u32 {
	return storer.new(root_object[T](obj))!
}

pub fn (mut storer Storer) generic_set[T](obj T) ! {
	storer.set(root_object[T](obj))!
}

pub fn (mut storer Storer) generic_delete[T](id u32) ! {
	storer.delete(id, root_object[T](T{}))
}

pub fn (mut storer Storer) generic_get[T](id u32) !T {
	root_object := storer.get(id)!
	return root_object.to_generic[T]()
}

pub fn (mut storer Storer) generic_list[T](ids []u32) ![]T {
	root_objects := storer.list(ids)!
	return root_objects.map(it.to_generic[T]())
}

// create_root_struct_table creates a table for a root_struct with columns for each index field
fn (mut storer Storer) generic_create_root_object_table[T]() ! {
	storer.create_root_object_table(root_object[T](T{}))!
}

// deletes an storer table belonging to a base object
fn (mut storer Storer) generic_delete_table[T]() ! {
	table_name := generic_get_table_name[T]()
	delete_query := 'delete table ${table_name}'
	storer.db.exec(delete_query)!
}
