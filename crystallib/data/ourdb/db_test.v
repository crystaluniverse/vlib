module ourdb

import os

const test_dir = '/tmp/ourdb'

fn test_basic_operations() {
	mut db := new(
		record_nr_max:   16777216 - 1 // max size of records
		record_size_max: 1024
		path:            test_dir
	)!

	defer {
		db.destroy() or { panic('failed to destroy db: ${err}') }
	}

	// Test set and get
	test_data := 'Hello, World!'.bytes()
	id := db.set(data: test_data)!

	retrieved := db.get(id)!
	assert retrieved == test_data

	// Test overwrite
	new_data := 'Updated data'.bytes()
	id2 := db.set(data: new_data)!
	retrieved2 := db.get(id2)!
	assert retrieved2 == new_data
}

fn test_auto_increment() {
	mut db := new(
		record_nr_max:   10 // max size of records
		record_size_max: 2
		path:            test_dir
	)!

	defer {
		db.destroy() or { panic('failed to destroy db: ${err}') }
	}

	// Create 5 objects with no ID specified (x=0)
	mut ids := []u32{}
	for i in 0 .. 5 {
		data := 'Object ${i + 1}'.bytes()
		id := db.set(data: data)!
		ids << id
	}

	// Verify IDs are incremental
	assert ids.len == 5
	for i in 0 .. 5 {
		assert ids[i] == i
		// Verify data can be retrieved
		data := db.get(ids[i])!
		assert data == 'Object ${i + 1}'.bytes()
	}
}

fn test_history_tracking() {
	mut db := new(
		record_nr_max:    16777216 - 1 // max size of records
		record_size_max:  1024
		path:             test_dir
		incremental_mode: false
	)!

	defer {
		db.destroy() or { panic('failed to destroy db: ${err}') }
	}

	// Create multiple versions of data
	key := u32(1)
	data1 := 'Version 1'.bytes()
	data2 := 'Version 2'.bytes()
	data3 := 'Version 3'.bytes()

	db.set(id: key, data: data1)!
	db.set(id: key, data: data2)!
	db.set(id: key, data: data3)!

	// Get history with depth 3
	history := db.get_history(key, 3)!
	assert history.len == 3
	assert history[0] == data3 // Most recent first
	assert history[1] == data2
	assert history[2] == data1
}

fn test_delete_operation() {
	mut db := new(
		record_nr_max:    16777216 - 1 // max size of records
		record_size_max:  1024
		path:             test_dir
		incremental_mode: false
	)!

	defer {
		db.destroy() or { panic('failed to destroy db: ${err}') }
	}

	// Set and then delete data
	test_data := 'Test data'.bytes()
	key := u32(1)
	db.set(id: key, data: test_data)!

	// Verify data exists
	retrieved := db.get(key)!
	assert retrieved == test_data

	// Delete data
	db.delete(key)!

	// Verify data is deleted
	retrieved_after_delete := db.get(key) or {
		assert err.msg() == 'Record not found'
		[]u8{}
	}
	assert retrieved_after_delete.len == 0
}

fn test_error_handling() {
	mut db := new(
		record_nr_max:   16777216 - 1 // max size of records
		record_size_max: 1024
		path:            test_dir
	)!

	defer {
		db.destroy() or { panic('failed to destroy db: ${err}') }
	}

	// Test getting non-existent key
	result := db.get(999) or {
		assert err.msg() == 'Record not found'
		[]u8{}
	}
	assert result.len == 0

	// Test deleting non-existent key
	db.delete(999) or {
		assert err.msg() == 'Record not found'
		return
	}
}

fn test_file_switching() {
	mut db := new(
		record_nr_max:    16777216 - 1 // max size of records
		record_size_max:  1024
		path:             test_dir
		file_size:        10
		incremental_mode: false
	)!

	defer {
		db.destroy() or { panic('failed to destroy db: ${err}') }
	}

	test_data1 := 'Test data'.bytes()
	key := u32(1)
	db.set(id: key, data: test_data1)!
	stat := os.stat('${db.path}/${db.last_used_file_nr}.db')!

	test_data2 := 'Test data 2222'.bytes()
	db.set(id: u32(2), data: test_data2)!

	location := db.lookup.get(u32(2))!
	assert location.file_nr == 1
}
