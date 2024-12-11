module db

import freeflowuniverse.crystallib.core.smartid
import freeflowuniverse.crystallib.data.ourtime
import freeflowuniverse.crystallib.data.encoder
import freeflowuniverse.crystallib.data.paramsparser
import json
import time

@[params]
pub struct NewArgs[T] {
pub mut:
	params      string // QUESTION: what are params for
	name        string // name of object
	description string // description of object
	mtime       string // modification time
	ctime       string // creation time
	object      T      // object that is being created
}

// new creates a new root object with id and base
// It doesn't register the created object to the db,
// the returned object must still be added using the set method.
pub fn (db DB) new[T](args NewArgs[T]) !T {
	base := db.new_base(
		params: args.params
		name: args.name
		description: args.description
		mtime: args.mtime
		ctime: args.ctime
	)!
	mut o := args.object
	o.Base = base
	return o
}

// set serializes and registers an object to the db with its index fields
pub fn (db DB) set[T](object T) ! {
	data := db.serialize[T](object)!

	mut index_int := map[string]int{}
	mut index_string := map[string]string{}
	$for field in T.fields {
		if field.attrs.contains('index') {
			$if field.typ is int {
				index_int[field.name] = object.$(field.name)
			}
			$if field.typ is string {
				index_string[field.name] = object.$(field.name)
			}
		}
	}
	db.set_data(
		gid: object.gid
		index_int: index_int
		index_string: index_string
		data: data
		baseobj: object.Base
	)!
}

pub fn (db DB) get[T](gid smartid.GID) !T {
	data := db.get_data(gid)!
	return db.unserialize[T](data)
}

@[params]
pub struct FindArgs[T] {
	BaseFindArgs
pub mut:
	object     T
	mtime_from ?ourtime.OurTime
	mtime_to   ?ourtime.OurTime
	ctime_from ?ourtime.OurTime
	ctime_to   ?ourtime.OurTime
}

// find on our database
//```js
// name  string
// color string
// nr    int
// nr2   int

// name       string
//```
pub fn (db DB) find[T](args FindArgs[T]) ![]T {
	mut query_int := map[string]int{}
	mut query_string := map[string]string{}

	$for field in T.fields {
		if field.attrs.contains('index') {
			$if field.typ is int {
				query_int[field.name] = args.object.$(field.name)
			}
			$if field.typ is string {
				query_string[field.name] = args.object.$(field.name)
			}
		}
	}
	dbfindoargs := DBFindArgs{
		query_int: query_int
		query_string: query_string
	}

	data := db.find_base(args.BaseFindArgs, dbfindoargs)!
	mut read_o := []T{}
	for d in data {
		read_o << db.unserialize[T](d)!
	}
	return read_o
}

//////////////////////serialization

// this is the method to dump binary form
pub fn (db DB) serialize[T](obj T) ![]u8 {
	mut enc := encoder.Encoder{}
	$for field in T.fields {
		$if field.typ is Base {
			enc = obj.$(field.name).bin_encoder()!
		}
	}
	$for field in T.fields {
		$if field.typ is int {
			enc.add_int(obj.$(field.name))
		}
		$if field.typ is string {
			enc.add_string(obj.$(field.name))
		}
		$if field.typ is []u32 {
			enc.add_list_u32(obj.$(field.name))
		}
	}
	return enc.data
}

// serialize to heroscript
pub fn (db DB) serialize_kwargs[T](obj T) !map[string]string {
	mut kwargs := obj.Base.serialize_kwargs()!

	$for field in T.fields {
		$if field.typ is int {
			val_int := obj.$(field.name)
			kwargs[field.name] = '${val_int}'
		}
		$if field.typ is string {
			kwargs[field.name] = obj.$(field.name)
		}
		$if field.typ is []u32 {
			mut listu32 := ''
			for i in obj.$(field.name) {
				listu32 += '${i},'
			}
			listu32 = listu32.trim_string_right(',')
			kwargs['listu32'] = listu32
		}
	}
	return kwargs
}

// this is the method to load binary form
pub fn (db DB) unserialize[T](data []u8) !T {
	// mut d := encoder.decoder_new(data)

	mut dec, base := base_decoder(data)!
	mut obj := T{
		Base: base
	}
	$for field in T.fields {
		$if field.typ is Base {
			// base already decoded above
		}
		$if field.typ is int {
			obj.$(field.name) = dec.get_int()
		}
		$if field.typ is string {
			obj.$(field.name) = dec.get_string()
		}
		$if field.typ is []u32 {
			obj.$(field.name) = dec.get_list_u32()
		}
	}
	return obj
}

// serialize to heroscript
pub fn (db DB) serialize_heroscript[T](obj T) !string {
	p := paramsparser.new_from_dict(db.serialize_kwargs[T](obj)!)!
	return p.export(pre: '!!${db.objtype}.define ')
}

pub fn (db DB) unserialize_heroscript[T](txt string) ![]T {
	mut res := []T{}
	for r in db.base_decoder_heroscript(txt)! {
		mut o := T{
			Base: r.base
		}
		p := r.params

		$for field in T.fields {
			$if field.typ is int {
				obj.$(field.name) = p.get_int_default(field.name, 0)!
			}
			$if field.typ is string {
				obj.$(field.name) = p.get_default(field.name, '')!
			}
			$if field.typ is []u32 {
				obj.$(field.name) = dec.get_list_u32(field.name)!
			}
		}
		res << o
	}
	return res
}
