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
pub fn (mut indexer Indexer) generic_new[T](obj T) !u32 {
	return indexer.new(root_object[T](obj))!
}

pub fn (mut indexer Indexer) generic_set[T](obj T) ! {
	indexer.set(root_object[T](obj))!
}

pub fn (mut indexer Indexer) generic_delete[T](id u32) ! {
	indexer.delete(id, root_object[T](T{}))
}

pub fn (mut indexer Indexer) generic_get[T](id u32) !T {
	obj_json := indexer.get_json(id, root_object[T](T{}))!
	return json.decode(T, obj_json)!
}

pub fn (mut indexer Indexer) generic_list[T]() ![]u32 {
	return indexer.list(root_object[T](T{}))
}

// filter lists root objects of type T that match provided index parameters and params.
pub fn (mut indexer Indexer) generic_filter[T, D](filter D, params FilterParams) ![]string {
	// TODO: make design decision for filter calls, below is a temporary hack
	mut obj := root_object[D](filter)
	obj.name = typeof[T]()
	return indexer.filter(obj, params)
}

// create_root_struct_table creates a table for a root_struct with columns for each index field
fn (mut indexer Indexer) generic_create_root_object_table[T]() ! {
	indexer.create_root_object_table(root_object[T](T{}))!
}

// deletes an indexer table belonging to a base object
fn (mut indexer Indexer) generic_delete_table[T]() ! {
	table_name := generic_get_table_name[T]()
	delete_query := 'delete table ${table_name}'
	indexer.db.exec(delete_query)!
}

// get_table_name returns the name of the table belonging to a root struct
fn generic_get_table_name[T]() string {
	mut table_name := ''
	$for attr in T.attributes {
		if attr.name == 'table' && attr.arg.len > 0 {
			table_name = attr.arg
		}
	}
	if table_name == '' {
		table_name = typeof[T]()
	}
	table_name = texttools.name_fix(table_name)
	table_name = table_name.replace('.', '_')
	return table_name
}
