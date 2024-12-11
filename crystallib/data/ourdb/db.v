module ourdb

import os

// OurDB is a simple key-value database implementation that provides:
// - Efficient key-value storage with history tracking
// - Data integrity verification using CRC32
// - Support for multiple backend files
// - Lookup table for fast data retrieval
//
// The database consists of three main components:
// 1. DB Interface (this file) - Provides the public API for database operations
// 2. Lookup Table - Maps keys to data locations for efficient retrieval
// 3. Backend Storage - Handles the actual data storage and file management

// set stores data at the specified key position
// The data is stored with a CRC32 checksum for integrity verification
// and maintains a linked list of previous values for history tracking
// Returns the ID used (either x if specified, or auto-incremented if x=0)
pub fn (mut db OurDB) set(x u32, data []u8) !u32 {
	location := db.lookup.get(x) or { Location{} } // Get location from lookup table if exists
	db.set_(x, location, data)!
	return db.lookup.set(x, location)!
}

// get retrieves data stored at the specified key position
// Returns error if the key doesn't exist or data is corrupted
pub fn (mut db OurDB) get(x u32) ![]u8 {
	location := db.lookup.get(x)! // Get location from lookup table
	return db.get_(location)!
}

// get_history retrieves a list of previous values for the specified key
// depth parameter controls how many historical values to retrieve (max)
// Returns error if key doesn't exist or if there's an issue accessing the data
pub fn (mut db OurDB) get_history(x u32, depth u8) ![][]u8 {
	mut result := [][]u8{}
	mut current_location := db.lookup.get(x)! // Start with current location

	// Traverse the history chain up to specified depth
	for i := u8(0); i < depth; i++ {
		// Get current value
		data := db.get_(current_location)!
		result << data

		// Try to get previous location
		current_location = db.get_prev_pos_(current_location) or { break }
		if current_location.position == 0 {
			break
		}
	}

	return result
}

// delete removes the data at the specified key position
// This operation zeros out the record but maintains the space in the file
// Use condense() to reclaim space from deleted records (happens in step after)
pub fn (mut db OurDB) delete(x u32) ! {
	db.lookup.delete(x)!

	// TODO: do we actually need to erase data?
	// location := db.lookup.get(x)! // Get location from lookup table
	// db.delete_(x, location)!
}

// close closes the database file
fn (mut db OurDB) lookup_dump_path() string {
	return '${db.path}/lookup_dump.db'
}

// load metadata i exists
fn (mut db OurDB) load() ! {
	if os.exists(db.lookup_dump_path()) {
		db.lookup.import_sparse(db.lookup_dump_path())!
	}
}

// make sure we have the metata stored on disk
fn (mut db OurDB) save() ! {
	// make sure we remember the data
	db.lookup.export_sparse(db.lookup_dump_path())!
}

// close closes the database file
fn (mut db OurDB) close() ! {
	db.save()!
	db.close_()
}

fn (mut db OurDB) destroy() ! {
	os.rmdir_all(db.path)!
}
