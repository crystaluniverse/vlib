module people

import freeflowuniverse.crystallib.core.playbook
import freeflowuniverse.crystallib.baobab.models.system
import db.sqlite

@[heap]
pub struct MemDB {
	system.ModelFactoryBase
pub mut:
	people    map[u32]&Person
	countries map[string]&Country
}

pub struct NewArgs {
pub mut:
	circle u32
	db     sqlite.DB
}

@[table: 'Person']
struct PersonTable {
	cid       int    @[primary; sql: serial] // is unique per circle
	id        string @[unique]               // needs to be unique as well per circle
	firstname string @[nonull]
	lastname  string @[nonull]
	data      string @[nonull] // will have the data
}

pub fn new(args NewArgs) !MemDB {
	mut m := MemDB{
		circle: args.circle
		db:     args.db
	}
	sql m.db {
		create table PersonTable
	}
	return m
}

pub fn (mut m MemDB) actions_import(path string) ! {
	ap := playbook.new(path: path)!
	m.actions(ap)!
}
