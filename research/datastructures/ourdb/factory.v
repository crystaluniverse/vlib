module ourdb

import os

const mbyte_=1000000

// OurDB represents a binary database with variable-length records
@[heap]
pub struct OurDB {
pub mut:
	path    string //is the directory in which we will have the lookup db as well as all the backend
	lookup  &LookupTable
	file    os.File
	file_nr u16 //the file which is open 
}


const header_size = 12


@[params]
pub struct OurDBConfig {
pub:
    record_nr_max u32 =   16777216 - 1    // max size of records
	record_size_max u32 = 1024*4   // max size in bytes of a record, is 4 KB default
	path string //directory where we will stor the DB

}


// new_memdb creates a new memory database with the given path and lookup table
pub fn new(args OurDBConfig) !OurDB {


  	mut keysize:=u8(4)

	if args.record_nr_max<65536{
		keysize=2
	}	else if args.record_nr_max<16777216{
		keysize=3
	}	else if args.record_nr_max<4294967296{
		keysize=4		
	} else{
		return error("max supported records is 4294967296 in OurDB")
	}

	if f64(args.record_size_max*args.record_nr_max)/2 > mbyte_ * 10 {
		keysize=6 //will use multiple files
	}

	//WILL NOT USE lookuppath YET

	// pub struct LookupConfig {
	// pub:
	//     size u32      // size of the table
	//     keysize u8    // size of each entry in bytes (2-8)
	//     lookuppath string // if set, use disk-based lookup
	// }
	mut l:=new_lookup(size:args.size,keysize:keysize)!

	mut db:= OurDB{
		path: path
		lookup: &l
	}	

	db.load()!

	return db

}
