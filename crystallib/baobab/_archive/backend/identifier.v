module backend

import db.pg

pub interface Identifier {
mut:
	init()!
	new_id(string) !u32 
	get_id(u32) !string
}

pub struct DBIdentifier {
pub:
	db 	pg.DB // database for storing base object ids
}

struct BaseObject {
    id int @[primary; sql: serial]
	object string 
}

pub fn (mut i DBIdentifier) init() ! {
	sql i.db {
	    create table BaseObject
	}!
}

pub fn (mut i DBIdentifier) new_id(object string) !u32 {
	obj := BaseObject{object:object}
	id := sql i.db {
		insert obj into BaseObject
	} or {return err}
	return u32(id)
}

pub fn (i DBIdentifier) get_id(id u32) !string {
	obj := sql i.db {
		select from BaseObject where id == id
	}!
	return obj[0].object
}


