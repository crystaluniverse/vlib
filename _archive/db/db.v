module system

// import sqlite
import freeflowuniverse.protocolme.models.people

pub struct DB {
pub mut:
	circle_name string
	circle_id   u32
	// sqldb sqlite.DB
	people people.MemDB
}

@[params]
pub struct DBArgs {
pub mut:
	circle_name string
	circle_id   u32
	// dbpath      string
	circle_path string
}

pub fn new(args_ DBArgs) !DB {
	mut args := args_
	// if args.dbpath == '' {
	// 	args.dbpath = '/tmp/baobab'
	// }
	if args.circle_id < 1 {
		return error('circle id needs to be > 0')
	}
	osal.dir_ensure(args.dbpath)!
	sqldb := sqlite.connect('${args.dbpath}/${args.circle_id}.db')!
	mut db := DB{
		dbpath:      args.dbpath
		circle_name: args.circle_name
		circle_id:   args.circle_id
		sqldb:       sqldb
	}

	// for each known model class we need to insert this
	db.people = people.new(circle: db.circle_id, db: db.sqldb)!

	return db
}
