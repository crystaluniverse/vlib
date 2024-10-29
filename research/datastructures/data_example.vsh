#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import ourdb
import os
import rand

fn main() {
	// Initialize lookup table with 1000 possible entries (using 3 bytes per entry)
	mut lookup := ourdb.new(1000, .m16)

    os.mkdir_all('/tmp/regiontest')!	
	
	// Create new ourdb
	db_path := '/tmp/regiontest/test.db'
	mut db := ourdb.new_memdb(db_path, &lookup)!
	
	// Store 10 random-sized records
	println('Storing random records...')
	for i in 0..10 {
		// Generate random size between 10 and 4096 bytes
		size := rand.int_in_range(10, 4097)!
		
		// Create random data
		mut data := []u8{len: size, init: 0}
		for j in 0..size {
			data[j] = u8(rand.int_in_range(32, 127)!)  // printable ASCII chars
		}
		
		// Store in database
		db.set(u32(i), data)!
		println('Stored record ${i}: ${size} bytes')
	}
	
	// Read back and verify some records
	println('\nReading back records...')
	for i in 0..10 {
		data := db.get(u32(i))!
		println('Retrieved record ${i}: ${data.len} bytes')
	}
	
	// Delete a few records
	println('\nDeleting records 3, 5, and 7...')
	db.delete(3)!
	db.delete(5)!
	db.delete(7)!
	
	// Condense the database
	println('\nCondensing database...')
	db.condense()!
	
	// Verify remaining records
	println('\nVerifying remaining records...')
	for i in 0..10 {
		if i !in [3, 5, 7] {
			data := db.get(u32(i))!
			println('Record ${i} still exists: ${data.len} bytes')
		}
	}
	
	// Clean up
	db.close()
	os.rm(db_path)!
	println('\nExample completed successfully')
}
