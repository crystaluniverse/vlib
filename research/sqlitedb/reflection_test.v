module db

import freeflowuniverse.crystallib.core.smartid
import freeflowuniverse.crystallib.data.ourtime
import freeflowuniverse.crystallib.data.encoder
import freeflowuniverse.crystallib.data.paramsparser
import json
import os
import time

const circlename = 'testci'
const objtype = 'TestStruct'

__global (
	test_begin ourtime.OurTime
	test_db    DB
)

struct TestStruct {
	Base
	text   string @[index]
	number int    @[index]
	u32s   []u32
}

fn testsuite_begin() {
	test_begin = ourtime.now()
	test_db = DB{
		circlename: db.circlename
		objtype: db.objtype
	}
	test_db.init()!
}

fn testsuite_end() {
	delete(
		cid: test_db.cid
		objtype: db.objtype
	)!
}

fn test_new() {
	object := test_db.new[TestStruct](
		name: 'Tester'
		description: 'A test object created for the sake of testing.'
		object: TestStruct{
			text: 'Test text'
			number: 42
			u32s: [u32(11), u32(101)]
		}
	)!

	// test base and object fields are filled in correctly
	assert smartid.gid_check(object.gid.str())
	assert object.version_base == 1
	assert object.serialization_type == .bin
	assert object.name == 'Tester'
	assert object.number == 42
}

fn test_set() {
	object := test_db.new[TestStruct](
		name: 'Tester'
		description: 'A test object created for the sake of testing.'
		object: TestStruct{
			text: 'Test text'
			number: 42
			u32s: [u32(11), u32(101)]
		}
	)!
	test_db.set[TestStruct](object)!

	// test that serialized object exists in db table
	serialized := test_db.serialize[TestStruct](object)!
	assert serialized == table_get(mut test_db, object.gid)!
}

fn test_get() {
	object := test_db.new[TestStruct](
		name: 'Tester'
		description: 'A test object created for the sake of testing.'
		object: TestStruct{
			text: 'Test text'
			number: 42
			u32s: [u32(11), u32(101)]
		}
	)!
	test_db.set[TestStruct](object)!
	assert object == test_db.get[TestStruct](object.gid)!
}

fn test_find_by_name() {
	object := test_db.new[TestStruct](
		name: 'FindByName'
		description: 'A test object created for the sake of testing.'
		object: TestStruct{
			text: 'Test text'
			number: 42
			u32s: [u32(11), u32(101)]
		}
	)!
	test_db.set[TestStruct](object)!
	found_objs := test_db.find[TestStruct](
		name: object.name
		object: TestStruct{}
	)!
	assert found_objs.len == 1
	assert found_objs[0] == object
}

fn test_find_by_mtime() {
	object := test_db.new[TestStruct](
		name: 'FindByMTime'
		description: 'A test object created for the sake of testing.'
		object: TestStruct{
			text: 'Test text'
			number: 42
			u32s: [u32(11), u32(101)]
		}
	)!
	test_db.set[TestStruct](object)!
	found_objs := test_db.find[TestStruct](
		mtime_from: test_begin
		mtime_to: ourtime.now()
		object: TestStruct{}
	)!
	assert found_objs.len == 4
	assert found_objs[3] == object
}

fn test_find_by_ctime() {
	object := test_db.new[TestStruct](
		name: 'FindByCTime'
		description: 'A test object created for the sake of testing.'
		object: TestStruct{
			text: 'Test text'
			number: 42
			u32s: [u32(11), u32(101)]
		}
	)!
	test_db.set[TestStruct](object)!
	found_objs := test_db.find[TestStruct](
		ctime_from: test_begin
		ctime_to: ourtime.now()
		object: TestStruct{}
	)!
	assert found_objs.len == 5
	assert found_objs[4] == object
}

fn test_find_by_index() {
	object := test_db.new[TestStruct](
		name: 'FindTester'
		description: 'A test object created for the sake of testing.'
		object: TestStruct{
			text: 'indextext'
			number: 77
			u32s: [u32(11), u32(101)]
		}
	)!
	test_db.set[TestStruct](object)!

	// find by string index
	mut found_objs := test_db.find[TestStruct](
		object: TestStruct{
			text: 'indextext'
		}
	)!
	assert found_objs.len == 1
	assert found_objs[0] == object

	// find by wrong string index
	found_objs = test_db.find[TestStruct](
		object: TestStruct{
			text: 'someindextext'
		}
	)!
	assert found_objs.len == 0

	// find by number index
	found_objs = test_db.find[TestStruct](
		object: TestStruct{
			number: 77
		}
	)!
	assert found_objs.len == 1
	assert found_objs[0] == object

	// find by wrong number index
	found_objs = test_db.find[TestStruct](
		object: TestStruct{
			number: 33
		}
	)!
	assert found_objs.len == 0

	// // attempt find by non-index field
	// found_objs = test_db.find[TestStruct](
	// 	object: TestStruct{
	// 		u32s: [u32(11), u32(101)]
	// 	}
	// )!
	// assert found_objs.len == 0
}

fn test_find() {
	object := test_db.new[TestStruct](
		name: 'FindTester'
		description: 'A test object created for the sake of testing.'
		object: TestStruct{
			text: 'test_find'
			number: 42
			u32s: [u32(11), u32(101)]
		}
	)!
	test_db.set[TestStruct](object)!

	// find without args
	mut found_objs := test_db.find[TestStruct](
		object: TestStruct{}
	)!
	assert found_objs.len == 7

	// find with both ctime and index
	found_objs = test_db.find[TestStruct](
		ctime_from: test_begin
		ctime_to: ourtime.now()
		object: TestStruct{
			text: 'test_find'
		}
	)!
	assert found_objs.len == 1
}
