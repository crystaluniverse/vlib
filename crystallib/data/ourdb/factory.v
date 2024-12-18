module ourdb

import os

const mbyte_ = 1000000

// OurDB represents a binary database with variable-length records
@[heap]
pub struct OurDB {
mut:
	lookup &LookupTable
pub:
	path             string // is the directory in which we will have the lookup db as well as all the backend
	incremental_mode bool
	file_size        u32 = 500 * (1 << 20) // 500MB
pub mut:
	file              os.File
	file_nr           u16 // the file which is open
	last_used_file_nr u16
}

const header_size = 12

@[params]
pub struct OurDBConfig {
pub:
	record_nr_max   u32 = 16777216 - 1    // max size of records
	record_size_max u32 = 1024 * 4        // max size in bytes of a record, is 4 KB default
	file_size       u32 = 500 * (1 << 20) // 500MB
	path            string // directory where we will stor the DB

	incremental_mode bool = true
}

// new_memdb creates a new memory database with the given path and lookup table
pub fn new(args OurDBConfig) !OurDB {
	mut keysize := u8(4)

	if args.record_nr_max < 65536 {
		keysize = 2
	} else if args.record_nr_max < 16777216 {
		keysize = 3
	} else if args.record_nr_max < 4294967296 {
		keysize = 4
	} else {
		return error('max supported records is 4294967296 in OurDB')
	}

	if f64(args.record_size_max * args.record_nr_max) / 2 > mbyte_ * 10 {
		keysize = 6 // will use multiple files
	}

	mut l := new_lookup(
		size:             args.record_nr_max
		keysize:          keysize
		incremental_mode: args.incremental_mode
	)!

	os.mkdir_all(args.path)!
	mut db := OurDB{
		path:             args.path
		lookup:           &l
		file_size:        args.file_size
		incremental_mode: args.incremental_mode
	}

	db.load()!

	return db
}
