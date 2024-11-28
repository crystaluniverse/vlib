module log

import db.sqlite

pub struct Logger {
	db_path string
	// DBBackend
}

pub fn new(db_path string) !Logger {
	db := sqlite.connect(db_path)!
	sql db {
		create table Log
	} or { panic(err) }
	return Logger{
		db_path: db_path
	}
}
