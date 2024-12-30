module main

import json
import db.sqlite
import freeflowuniverse.crystallib.baobab.actor_backend
import log
import os
// import freeflowuniverse.crystallib.clients.redisclient

const db_path = '${os.dir(@FILE)}/example.sqlite'

@[table: 'example_structs']
@[root_struct]
pub struct ExampleStruct {
	id          int // unique serial root object id
	name        string @[index]
	description string
}

pub fn main() {
	do() or { panic(err) }
}

pub fn do() ! {
	mut logger := log.Logger(&log.Log{
		level: $if debug { .debug } $else { .info }
	})

	logger.info('Creating new SQLite backend.')
	logger.info('Database is located at: ${db_path}')
	mut backend := actor_backend.new(db_path)!

	example_obj := ExampleStruct{
		name: 'example'
		description: 'an example root object'
	}
	logger.info('Created new root object: ${example_obj}')
	id := backend.new[ExampleStruct](example_obj)!
	logger.info('Added root object to backend, id is ${id}')

	logger.info('Listing backend root objects of type ExampleStruct')
	objects := backend.list[ExampleStruct]()!
	logger.info('Backend returned: ${objects}')

	logger.info('Getting backend root object of type ExampleStruct with id ${id}')
	object := backend.get[ExampleStruct](id)!
	logger.info('Backend returned: ${object}')

	logger.info('Getting backend root object of type ExampleStruct with invalid id ${id + 1}')
	backend.get[ExampleStruct](id + 1) or { logger.error('Backend returned error: ${err}') }

	example_obj1 := ExampleStruct{
		name: 'another_example'
		description: 'another example root object'
	}
	logger.info('Created new root object: ${example_obj1}')
	id1 := backend.new[ExampleStruct](example_obj1)!
	logger.info('Added root object to backend, id is ${id1}')

	logger.info('Filtering backend root objects of type ExampleStruct with name ${example_obj1.name}')
	filtered_objects := backend.filter[ExampleStruct](
		indices: {
			'name': 'another_example'
		}
	)!
	logger.info('Backend returned: ${filtered_objects}')
}
