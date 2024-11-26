module db

import db.sqlite
import freeflowuniverse.crystallib.core.smartid
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.ui.console

__global (
	dbs      shared map[string]DB // key is cidstr__objtype
	dbs_init shared map[string]bool
)

@[heap]
pub struct DB {
pub mut:
	cid        smartid.CID
	version    u8 // 1 is binary, 2 is json, 3 is heroscript
	circlename string
	objtype    string
	sqlitedb   sqlite.DB
	datapath   ?pathlib.Path
}

fn key(cid smartid.CID, objtype_ string) string {
	objtype := texttools.name_fix(objtype_)
	return '${cid.str()}__${objtype}'
}

// init creates the db file, creates an sqlite db connection pool, and adds the pool to the dbs map
pub fn (mut mydb DB) init() ! {
	if mydb.circlename.len == 0 {
		return error('circle name needs to be specified')
	}
	mydb.cid = smartid.cid(name: mydb.circlename)!
	mut heropath := pathlib.get_dir(path: '~/hero/db', create: true)!
	mut sqlitedb := sqlite.connect('${heropath.path}/${mydb.cid.str()}.db')!
	mydb.sqlitedb = sqlitedb
	lock dbs {
		k := key(mydb.cid, mydb.objtype)
		// console.print_debug('init key: ${k}')
		dbs[k] = &mydb
	}
}

pub fn set(args_ DBSetArgs) ! {
	mut args := args_
	lock dbs {
		k := key(args.gid.cid, args.objtype)
		mut mydb := dbs[k] or { return error('cannot find db with key: ${k} for set') }
		table_set(mut mydb, mut args)!
	}
}

@[params]
pub struct DBTableCreateArgs {
pub mut:
	cid          smartid.CID
	objtype      string // unique type name for obj class
	index_int    []string
	index_string []string
}

// create required tables for requested object
pub fn create(args_ DBTableCreateArgs) ! {
	mut args := args_
	mut tablename := ''
	k := key(args.cid, args.objtype)
	lock dbs {
		mydb := dbs[k] or { return error('cannot find db with key:${k} for create.') }
		tablename = table_name_find(mydb)
	}
	lock dbs_init {
		if tablename in dbs_init {
			return
		}
	}
	// console.print_debug('create db & tables: ${k}')
	lock dbs {
		// console.print_debug('create table for ${args_}')
		mut mydb2 := dbs[k] or { return error('cannot find db with key: ${k} for create 2.') }
		tables_create(mut mydb2, mut args)!
	}
	lock dbs_init {
		dbs_init[tablename] = true
	}
}

@[params]
pub struct DBTableGetArgs {
pub mut:
	gid     smartid.GID @[required]
	objtype string      @[required]
}

// get the data from DB if you know the gid
pub fn get(args DBTableGetArgs) ![]u8 {
	lock dbs {
		k := key(args.gid.cid, args.objtype)
		mut mydb := dbs[k] or { return error('cannot find db with key:${k} for get') }
		return table_get(mut mydb, args.gid)!
	}
	panic('bug')
}

@[params]
struct DBFindArgsI {
mut:
	cid               smartid.CID       @[required]
	objtype           string            @[required]
	query_int         map[string]int
	query_string      map[string]string
	query_int_less    map[string]int
	query_int_greater map[string]int
}

pub fn find(args DBFindArgsI) ![][]u8 {
	lock dbs {
		k := key(args.cid, args.objtype)
		mut mydb := dbs[k] or { return error('cannot find db with cid: ${k} for find') }
		return table_find(mydb, args)
	}
	panic('bug')
}

@[params]
pub struct DBDeleteArgs {
pub mut:
	cid     smartid.CID  @[required]
	gid     ?smartid.GID
	objtype string       @[required]
}

pub fn delete(args DBDeleteArgs) ! {
	lock dbs {
		k := key(args.cid, args.objtype)
		mut mydb := dbs[k] or { return error('cannot find db with cid: ${k} for delete') }

		table_delete(mut mydb, args)!
	}
}
