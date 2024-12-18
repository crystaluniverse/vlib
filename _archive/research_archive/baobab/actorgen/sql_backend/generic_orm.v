module main

import json
import db.sqlite
// import freeflowuniverse.crystallib.clients.redisclient

pub struct SQLiteBackend {
	db sqlite.DB
}

@[table: 'root_objects']
pub struct RootObject {
	id    int @[primary; sql: serial] // unique serial root object id
	table string // name of table root object is in
}

@[table: 'example_structs']
pub struct ExampleStruct {
	id          int // unique serial root object id
	name        string @[index]
	description string
}

// save the session to redis & mem
pub fn (mut backend SQLiteBackend) new[T](mut obj T) ! {
	mut table_name := ''
	$for attr in T.attributes {
		if attr.name == 'table' && attr.arg.len > 0 {
			table_name = attr.arg
		}
	}
	row := RootObject{
		table: table_name
	}

	sql backend.db {
		insert row into RootObject
	}!

	id := backend.db.last_id()

	// create table for root object if it doesn't exist
	mut columns := ['id integer primary key AUTOINCREMENT', 'data TEXT']
	$for field in T.fields {
		if field.attrs.contains('index') {
			columns << '${field.name} TEXT'
		}
	}
	create_query := 'create table if not exists ${table_name} (${columns.join(',')})'
	backend.db.exec(create_query)!

	obj_encoded := json.encode(obj)
	// insert root object into its table
	mut indices := ['id', 'data']
	mut values := ['${id}', "'${obj_encoded}'"]
	$for field in T.fields {
		$if field.typ is string {
			if field.attrs.contains('index') {
				indices << '${field.name}'
				val := obj.$(field.name)
				values << "'${val}'"
			}
		}
	}
	insert_query := 'insert into ${table_name} (${indices.join(',')}) values (${values.join(',')})'
	backend.db.exec(insert_query)!
}

// save the session to redis & mem
pub fn (mut backend SQLiteBackend) set[T](mut obj T) ! {
	mut table_name := ''
	$for attr in T.attributes {
		if attr.name == 'table' && attr.arg.len > 0 {
			table_name = attr.arg
		}
	}
	obj_encoded := json.encode(obj)

	// todo: check table and entry exists
	db.exec("update ${table_name} set data='${obj_encoded}' where id=${obj.id}")!
}

// save the session to redis & mem
pub fn (mut backend SQLiteBackend) get[T](id int) ?T {
	mut table_name := ''
	$for attr in T.attributes {
		if attr.name == 'table' && attr.arg.len > 0 {
			table_name = attr.arg
		}
	}
	// todo: check table and entry exists
	db.exec('select * from ${table_name} where id=${id}')!
}

// save the session to redis & mem
pub fn (mut backend SQLiteBackend) list[T]() []T {
	mut table_name := ''
	$for attr in T.attributes {
		if attr.name == 'table' && attr.arg.len > 0 {
			table_name = attr.arg
		}
	}
	// todo: check table and entry exists
	response := db.exec('select * from ${table_name}') or { panic(err) }
	if response.len == 0 {
		panic('response shouldnt be 0')
	}

	// return response[0].vals
}

pub fn main() {
	do() or { panic(err) }
}

pub fn do() ! {
	mut backend := SQLiteBackend{
		db: sqlite.connect('example.sqlite')!
	}

	sql backend.db {
		create table RootObject
	}!

	mut example_obj := ExampleStruct{
		name:        'example'
		description: 'an example root object'
	}

	backend.new[ExampleStruct](mut example_obj)!
	items := backend.list[ExampleStruct]()
	println('items: ${items}')
}
