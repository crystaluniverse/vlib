module dbfs

import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.crypt.aes_symmetric
import encoding.base64
// import freeflowuniverse.crystallib.ui.console

@[heap]
pub struct DB {
mut:
	config DBConfig
pub mut:
	path   pathlib.Path
	parent &DBCollection @[skip; str: skip]
	namedb ?NameDB // optional namedb which is for hashed keys
}

pub struct DBConfig {
mut:
	encrypted bool
pub:
	name       string
	withkeys   bool   // if set means we will use keys in stead of only u32
	keyshashed bool   // if its ok to hash the keys, which will generate id out of these keys and its more scalable
	ext        string // extension if we want to use it in DB e.g. 'json'
	// base64 bool //if binary data will be base encoded, not used now
}

@[params]
pub struct GetArgs {
pub mut:
	key string
	id  u32
}

// get the value, if it doesn't exist then return empty string
pub fn (mut db DB) get(args_ GetArgs) !string {
	mut args := args_
	args.key = texttools.name_fix(args.key)
	mut pathsrc := pathlib.Path{}
	if args.key.len > 0 {
		if args.id > 0 {
			return error("cann't specify id and key")
		}
		if db.config.withkeys {
			if db.config.keyshashed {
				// means we use a namedb
				mut ndb := db.namedb or { panic('namedb should be available') }

				args.id, _ = ndb.get(args.key)!
				pathsrc = db.path_get(args.id)!
			} else {
				// now we need to use the link as set
				mut datapath0 := '${db.path.path}/${args.key}'
				if db.config.ext.len > 0 {
					datapath0 += '.${db.config.ext}'
				}
				pathsrc = pathlib.get_link(path: datapath0, create: false)!
			}
		} else {
			pathsrc = db.path_get(args.id)!
		}
	} else if args.id > 0 {
		pathsrc = db.path_get(args.id)!
	} else {
		return error('either id or key has to be specified')
	}

	mut data := pathsrc.read()!
	if data.len == 0 {
		panic('data cannot be empty for get:${args}')
	}
	if db.is_encrypted() {
		data = aes_symmetric.decrypt_str(data, db.secret()!)
	}
	return data
}

@[params]
pub struct SetArgs {
pub mut:
	key    string
	id     u32
	value  string
	valueb []u8 // as bytes
}

// set the key/value will go to filesystem, is organzed per context and each db has a name
pub fn (mut db DB) set(args_ SetArgs) !u32 {
	// console.print_debug(args_)
	mut args := args_
	if args.value.len == 0 && args.valueb.len == 0 {
		return error('specify for value or valueb, now both empty')
	}
	if args.key.len > 0 {
		args.key = texttools.name_fix(args.key)
	}

	if args.value.len > 0 {
		args.valueb = args.value.bytes()
		args.value = ''
	}

	mut pathsrc := pathlib.Path{}

	// lets deal with key
	if args.key.len > 0 {
		if args.id > 0 {
			return error('cant have id and key at same time')
		}
		if !db.config.withkeys {
			return error('db needs to be with keys')
		}
		if db.config.keyshashed {
			// means we use a namedb
			mut ndb := db.namedb or { panic('namedb should be available') }

			args.id = ndb.set(args.key, '')!
			pathsrc = db.path_get(args.id)!
		} else {
			mut datapath0 := '${db.path.path}/${args.key}'
			if db.config.ext.len > 0 {
				datapath0 += '.${db.config.ext}'
			}
			pathsrc = pathlib.get_link(path: datapath0, create: false)!
			if !pathsrc.exists() {
				args.id = db.parent.incr()!
				mut destname := '${db.path.path}/${args.key}'
				if db.config.ext.len > 0 {
					destname += '.${db.config.ext}'
				}
				pathsrc = db.path_get(args.id)!
				pathsrc.write('')!
				pathsrc.link(destname, true)! // link the key to the right source info					
			} else {
				mut p3 := pathsrc.getlink()!
				p3_name := p3.name()
				args.id = p3_name.u32()
			}
		}
	} else if args.id > 0 {
		pathsrc = db.path_get(args.id)!
	} else {
		args.id = db.parent.incr()!
		pathsrc = db.path_get(args.id)!
	}
	console.print_debug("keydb ${pathsrc}")
	if db.config.encrypted {
		args.valueb = aes_symmetric.encrypt(args.valueb, db.secret()!)
		pathsrc.write(base64.encode(args.valueb))!
	} else {
		pathsrc.writeb(args.valueb)!
	}

	assert args.id > 0
	return args.id
}

// get path based on int id in the DB
fn (mut db DB) path_get(myid u32) !pathlib.Path {
	a, b, c := namedb_dbid(myid)
	mut destname := c.str()
	if db.config.ext.len > 0 {
		destname += '.${db.config.ext}'
	}
	mut mydatafile := pathlib.get_file(
		path: '${db.path.path}/${a}/${b}/${destname}'
		create: false
	)!
	return mydatafile
}

// check if entry exists based on keyname
pub fn (mut db DB) exists(args_ GetArgs) !bool {
	mut args := args_
	args.key = texttools.name_fix(args.key)
	mut pathsrc := pathlib.Path{}
	if args.key.len > 0 {
		if args.id > 0 {
			return error("cann't specify id and key")
		}
		if !db.config.withkeys {
			return error('db needs to be with keys')
		}
		if db.config.keyshashed {
			// means we use a namedb
			mut ndb := db.namedb or { panic('namedb should be available') }

			return ndb.exists(args.key)!
		} else {
			mut datapath0 := '${db.path.path}/${args.key}'
			if db.config.ext.len > 0 {
				datapath0 += '.${db.config.ext}'
			}
			pathsrc = pathlib.get_link(path: datapath0, create: false)!
		}
	} else {
		pathsrc = db.path_get(args.id)!
	}
	return pathsrc.exists()
}

// delete an entry
pub fn (mut db DB) delete(args_ GetArgs) ! {
	mut args := args_
	if args.key.len > 0 {
		args.key = texttools.name_fix(args.key)
	}
	mut pathsrc := pathlib.Path{}
	if args.key.len > 0 {
		if args.id > 0 {
			return error('cant have id and key at same time')
		}
		if !db.config.withkeys {
			return error('db needs to be with keys')
		}
		if db.config.keyshashed {
			// means we use a namedb
			mut ndb := db.namedb or { panic('namedb should be available') }

			args.id, _ = ndb.get(args.key)!
			pathsrc = db.path_get(args.id)!
			ndb.delete(args.key)!
		} else {
			mut datapath0 := '${db.path.path}/${args.key}'
			if db.config.ext.len > 0 {
				datapath0 += '.${db.config.ext}'
			}
			pathsrc = pathlib.get_link(path: datapath0, create: false)!
			if pathsrc.exists() {
				mut p3 := pathsrc.getlink()!
				p3.delete()!
			}
		}
	} else {
		pathsrc = db.path_get(args.id)!
	}
	pathsrc.delete()!
}

// delete the db, will not be able to use it any longer
pub fn (mut db DB) destroy() ! {
	db.path.delete()!
}

// get all keys of the db (e.g. per session) can be with a prefix
pub fn (mut db DB) keys(prefix_ string) ![]string {
	// TODO: see get, to fix this one
	mut files := db.path.list()!

	panic('implement ${files}')
	prefix := texttools.name_fix(prefix_)
	mut r := db.path.list(recursive: false)!
	mut res := []string{}
	for item in r.paths {
		name := item.name()
		if prefix == '' || name.starts_with(prefix) {
			res << name
		}
	}
	return res
}

// get all keys of the db (e.g. per session) can be with a prefix
pub fn (mut db DB) ids() ![]u32 {
	// TODO: see get, to fix this one
	mut files := db.path.list(files_only: true)!
	mut res := []u32{}
	for file in files.paths {
		res << u32(file.name().int())
	}
	return res
}

// delete all data
pub fn (mut db DB) empty() ! {
	db.path.empty()!
}

fn (mut db DB) secret() !string {
	if db.is_encrypted() {
		return db.parent.secret
	}
	return ''
}

// will mark db for encryption .
// will go over all existing keys and encrypt
pub fn (mut db DB) encrypt() ! {
	// TODO: see get, to fix this one
	if db.config.encrypted {
		return
	}
	db.secret()! // just to check if ok
	for key in db.keys('')! {
		v := db.get(key: key)!
		encrypted_v := aes_symmetric.encrypt(v.bytes(), db.secret()!)
		db.set(key: key, valueb: encrypted_v)!
	}

	db.config.encrypted = true
	db.path.file_get_new('encrypted')!
}

pub fn (db DB) is_encrypted() bool {
	return db.config.encrypted
}
