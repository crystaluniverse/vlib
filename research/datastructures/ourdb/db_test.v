module ourdb

const test_dir = '/tmp/ourdb'

fn test_basic_operations() {
	mut db := new(
		record_nr_max: 16777216 - 1 // max size of records
		record_size_max: 1024
		path: ourdb.test_dir
	)!

	defer {
		db.destroy() or { panic('failed to destroy db: ${err}') }
	}

	// Test set and get
	test_data := 'Hello, World!'.bytes()
	db.set(1, test_data)!

	retrieved := db.get(1)!
	assert retrieved == test_data

	// Test overwrite
	new_data := 'Updated data'.bytes()
	db.set(1, new_data)!
	retrieved2 := db.get(1)!
	assert retrieved2 == new_data
}

fn test_history_tracking() {
	mut db := new(
		record_nr_max: 16777216 - 1 // max size of records
		record_size_max: 1024
		path: ourdb.test_dir
	)!

	defer {
		db.destroy() or { panic('failed to destroy db: ${err}') }
	}

	// Create multiple versions of data
	key := u32(1)
	data1 := 'Version 1'.bytes()
	data2 := 'Version 2'.bytes()
	data3 := 'Version 3'.bytes()

	db.set(key, data1)!
	db.set(key, data2)!
	db.set(key, data3)!

	// Get history with depth 3
	history := db.get_history(key, 3)!
	assert history.len == 3
	assert history[0] == data3 // Most recent first
	assert history[1] == data2
	assert history[2] == data1
}

fn test_delete_operation() {
	mut db := new(
		record_nr_max: 16777216 - 1 // max size of records
		record_size_max: 1024
		path: ourdb.test_dir
	)!

	defer {
		db.destroy() or { panic('failed to destroy db: ${err}') }
	}

	// Set and then delete data
	test_data := 'Test data'.bytes()
	key := u32(1)
	db.set(key, test_data)!

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
		record_nr_max: 16777216 - 1 // max size of records
		record_size_max: 1024
		path: ourdb.test_dir
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
