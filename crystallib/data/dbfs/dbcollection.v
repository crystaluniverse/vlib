module dbfs

import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.core.texttools
// import freeflowuniverse.crystallib.clients.redisclient	
import os
import json
// import freeflowuniverse.crystallib.ui.console

@[heap]
pub struct DBCollection {
pub mut:
	path           pathlib.Path
	contextid      u32
	secret         string
	memberid       u16 // needed to do autoincrement of the DB, when user logged in we need memberid, memberid is unique per circle
	member_pubkeys map[int]string
	// redis redisclient.Redis
}

pub fn (mut dbcollection DBCollection) incr() !u32 {
	mut incr_file := dbcollection.path.file_get_new('incr_${dbcollection.memberid}')!
	c := incr_file.read() or { '' }
	mut c_int := c.u32()
	if c == '' {
		c_int = 256 * 256 * dbcollection.memberid // in future we will have to check that we don't go over range for 1 member
	}
	c_int += 1
	incr_file.write('${c_int}')!
	return c_int
}

@[params]
pub struct DBCreateArgs {
pub mut:
	name       string
	encrypted  bool
	withkeys   bool // if set means we will use keys in stead of only u32
	keyshashed bool // if its ok to hash the keys, which will generate id out of these keys and its more scalable
}

// create the dabase (init), cannot use unless this is done
//```
// name string
// encrypted bool
// withkeys bool //if set means we will use keys in stead of only u32
// keyshashed bool //if its ok to hash the keys, which will generate id out of these keys and its more scalable
//```
pub fn (mut dbcollection DBCollection) db_create(args_ DBCreateArgs) !DB {
	mut args := args_
	args.name = texttools.name_fix(args.name)
	mut p := pathlib.get_dir(create: true, path: '${dbcollection.path.path}/${args.name}')!
	cfg := DBConfig{
		withkeys: args.withkeys
		name: args.name
		encrypted: args.encrypted
		keyshashed: args.keyshashed
	}
	mut path_meta := p.file_get('.meta') or {
		p2 := pathlib.get_file(path: '${p.path}/.meta', create: true)!
		p2
	}
	metadata := json.encode(cfg)
	path_meta.write(metadata)!

	return dbcollection.db_get(args.name)
}

pub fn (mut dbcollection DBCollection) db_get_create(args_ DBCreateArgs) !DB {
	if dbcollection.exists(args_.name) {
		return dbcollection.db_get(args_.name)!
	}
	mut args := args_
	args.name = texttools.name_fix(args.name)
	mut p := pathlib.get_dir(create: true, path: '${dbcollection.path.path}/${args.name}')!
	cfg := DBConfig{
		withkeys: args.withkeys
		name: args.name
		encrypted: args.encrypted
		keyshashed: args.keyshashed
	}
	mut path_meta := p.file_get('.meta') or {
		p2 := pathlib.get_file(path: '${p.path}/.meta', create: true)!
		p2
	}
	metadata := json.encode(cfg)
	path_meta.write(metadata)!

	return dbcollection.db_get(args.name)
}

// get a DB from the dbcollection
pub fn (mut dbcollection DBCollection) db_get(name_ string) !DB {
	name := texttools.name_fix(name_)
	dirpath := '${dbcollection.path.path}/${name}'
	mut p := pathlib.get_dir(create: false, path: dirpath) or {
		return error('cant open dabase or find on ${dirpath}')
	}
	mut path_meta := p.file_get('.meta') or {
		p2 := pathlib.get_file(path: '${p.path}/.meta', create: true)!
		p2
	}
	data := path_meta.read()!
	mut cfg := DBConfig{}
	if data.len > 0 {
		cfg = json.decode(DBConfig, data)!
	}
	mut db := DB{
		path: p
		config: cfg
		parent: &dbcollection
	}
	if cfg.encrypted {
		if dbcollection.secret.len < 4 {
			return error('secret needs to be specified on dbcollection level, now < 4 chars. \nDB: ${dbcollection}')
		}
	}
	if db.config.withkeys {
		if db.config.keyshashed {
			// means we use a namedb
			db.namedb = namedb_new('${db.path.path}/names')!
		}
	}
	return db
}

pub fn (mut dbcollection DBCollection) get_encrypted(name_ string) !DB {
	mut db := dbcollection.db_get(name_)!
	db.encrypt()!
	return db
}

pub fn (mut collection DBCollection) exists(name_ string) bool {
	name := texttools.name_fix(name_)
	return os.exists('${collection.path.path}/${name}')
}

pub fn (mut collection DBCollection) delete(name_ string) ! {
	name := texttools.name_fix(name_)
	mut datafile := collection.path.dir_get(name) or { return }
	datafile.delete()!
}

pub fn (mut collection DBCollection) list() ![]string {
	mut r := collection.path.list(recursive: false, dirs_only: true)!
	mut res := []string{}
	for item in r.paths {
		res << item.name()
	}
	return res
}

pub fn (mut collection DBCollection) prefix(prefix string) ![]string {
	mut res := []string{}
	for item in collection.list()! {
		// console.print_debug(" ---- $item ($prefix)")
		if item.trim_space().starts_with(prefix) {
			// console.print_debug("888")
			res << item
		}
	}
	return res
}

// delete all data in the dbcollection (be careful)
pub fn (mut collection DBCollection) destroy() ! {
	collection.path.delete()!
}
