#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.data.ourdb
import os

fn main() {
	println('Starting database test...')

	// Initialize database
	mut db := ourdb.new(path: '/tmp/mydb') or {
		println('Failed to create database: ${err}')
		exit(1)
	}
	println('Database initialized successfully')

	// Test data
	test_string := 'Hello World'
	
	// Store data
	db.set(1, test_string.bytes()) or {
		println('Failed to store data: ${err}')
		exit(1)
	}
	println('Data stored successfully')

	// Retrieve and verify data
	data := db.get(1) or {
		println('Failed to retrieve data: ${err}')
		exit(1)
	}
	retrieved_string := data.bytestr()
	
	if retrieved_string != test_string {
		println('Data verification failed!')
		println('Expected: ${test_string}')
		println('Got: ${retrieved_string}')
		exit(1)
	}
	println('Data retrieved and verified successfully')

	// Test history
	history := db.get_history(1, 5) or {
		println('Failed to get history: ${err}')
		exit(1)
	}
	println('History retrieved successfully: ${history.len} entries found')

	// Test deletion
	db.delete(1) or {
		println('Failed to delete data: ${err}')
		exit(1)
	}
	println('Data deleted successfully')

	// Verify deletion
	deleted_data := db.get(1) or {
		if err.msg().contains('not found') {
			println('Deletion verified successfully')
			exit(0)
		}
		println('Unexpected error after deletion: ${err}')
		exit(1)
	}
	println('Error: Data still exists after deletion!')
	exit(1)
}
