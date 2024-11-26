module dbfs

import freeflowuniverse.crystallib.core.texttools

// will use default connection and get database with name as specified
// is not encrypted
pub fn db_get(name_ string) !DB {
	mut name := texttools.name_fix(name_)
	if name == '' {
		name = 'core'
	}

	mut defaultcollection := get()!

	// name string
	// encrypted bool
	// withkeys bool //if set means we will use keys in stead of only u32
	// keyshashed bool //if its ok to hash the keys, which will generate id out of these keys and its more scalable

	mut db := defaultcollection.db_create(name: name, withkeys: true)!

	if db.config.encrypted {
		return error('db is encrypted and should not be')
	}

	return db
}

// will use default connection and get database with name as specified, if not specified then name=core
// is not encrypted
pub fn db_encrypted(name_ string, secret string) !DB {
	mut name := texttools.name_fix(name_)
	mut defaultcollection := get(secret: secret)!

	mut db := defaultcollection.db_create(name: name, withkeys: true)!

	db.encrypt()!

	return db
}
