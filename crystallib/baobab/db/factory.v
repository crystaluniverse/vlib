module db

import db.sqlite
import freeflowuniverse.crystallib.baobab.smartid
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.core.texttools

__global (
	dbs      shared map[string]DB // key is cidstr__objtype
	dbs_init shared map[string]bool
)

[heap]
pub struct DB {
pub mut:
	cid        smartid.CID
	version    u8 // 1 is binary, 2 is json, 3 is 3script
	circlename string
	objtype    string
	sqlitedb   sqlite.DB
	datapath   ?pathlib.Path
}

fn key(cid smartid.CID, objtype_ string) string {
	objtype := texttools.name_fix(objtype_)
	return '${cid.str()}__${objtype}'
}

pub fn (mut mydb DB) init() ! {
	if mydb.circlename.len==0{
		return error("circle name needs to be specified")
	}
	mydb.cid = smartid.cid(name: mydb.circlename)!
	mut heropath := pathlib.get_dir(path: '~/hero/db', create: true)!
	mut sqlitedb := sqlite.connect('${heropath.path}/${mydb.cid.str()}.db')!
	mydb.sqlitedb = sqlitedb
	tables_create_core(mut mydb)! // creates the data table
	lock dbs {
		k:=key(mydb.cid, mydb.objtype)
		println('init key: ${k}')
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

[params]
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
	println('create key: ${k}')
	lock dbs {
		mydb := dbs[k] or { return error('cannot find db with key:${k} for create.') }
		tablename = table_name(mydb, args.objtype)
	}

	lock dbs_init {
		if tablename in dbs_init {
			return
		}
	}
	lock dbs {
		// println('create table for ${args_}')
		mut mydb2 := dbs[k] or { return error('cannot find db with key: ${k} for create 2.') }
		tables_create(mut mydb2, mut args)!
	}
	lock dbs_init {
		dbs_init[tablename] = true
	}
}

[params]
pub struct DBTableGetArgs {
pub mut:
	gid     smartid.GID [required]
	objtype string      [required]
}

// get the data from DB if you know the gid
pub fn get(args DBTableGetArgs) ![]u8 {
	lock dbs {
		k := key(args.gid.cid, args.objtype)
		mut mydb := dbs[k] or { return error('cannot find db with key:${k} for get') }
		return table_get(mut mydb, args.gid)!
	}
	panic("bug")
}

[params]
pub struct DBFindArgs {
pub mut:
	cid               smartid.CID [required]
	objtype           string [required]
	query_int         map[string]int
	query_string      map[string]string
	query_int_less    map[string]int
	query_int_greater map[string]int
}

pub fn find(args DBFindArgs) ![][]u8 {
	lock dbs {
		k:=key(args.cid, args.objtype)
		mut mydb := dbs[k] or {
			return error('cannot find db with cid: ${k} for find')
		}
		return table_find(mut mydb, args)
	}
	panic("bug")
}

[params]
pub struct DBDeleteArgs {
pub mut:
	cid     smartid.CID  [required]
	gid     ?smartid.GID
	objtype string       [required]
}

pub fn delete(args DBDeleteArgs) ! {
	lock dbs {
		k := key(args.cid, args.objtype)
		mut mydb := dbs[k] or {
			return error('cannot find db with cid: ${k} for delete')
		}

		table_delete(mut mydb, args)!
	}
}
