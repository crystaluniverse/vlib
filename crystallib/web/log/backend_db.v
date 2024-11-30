module log

import db.sqlite

pub struct DBBackend {
pub:
	db sqlite.DB
}

@[params]
pub struct DBBackendConfig {
pub:
	db sqlite.DB
}

// factory for
pub fn new_backend(config DBBackendConfig) !DBBackend {
	sql config.db {
		create table Log
	} or { panic(err) }

	return DBBackend{
		db: config.db
	}
}
