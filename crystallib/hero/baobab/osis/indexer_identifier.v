module osis

import db.pg

struct BaseObject {
    id int @[primary; sql: serial]
	object string 
}

pub fn (mut i Indexer) init() ! {
	sql i.db {
	    create table BaseObject
	}!
}

pub fn (mut i Indexer) new_id(object string) !u32 {
	obj := BaseObject{object:object}
	id := sql i.db {
		insert obj into BaseObject
	} or {return err}
	return u32(id)
}

pub fn (i Indexer) get_id(id u32) !string {
	obj := sql i.db {
		select from BaseObject where id == id
	}!
	return obj[0].object
}