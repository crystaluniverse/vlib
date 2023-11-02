module mystruct

import freeflowuniverse.crystallib.baobab.db
import freeflowuniverse.crystallib.baobab.smartid
import json
import time

const objtype = 'mystruct'

pub struct MyDB {
	db.DB
}

pub struct MyStruct {
	db.Base
pub mut:
	nr      int
	color   string
	nr2     int
	listu32 []u32
}

// TODO: use enumerator and do differently (despiegk)
[params]
pub struct DBArgs {
pub mut:
	circlename string
	version    u8 = 1 // 1 is bin, 2 is json, 3 is 3script
}

pub fn db_new(args DBArgs) !MyDB {
	mut mydb := MyDB{
		circlename: args.circlename
		version: args.version
		objtype: mystruct.objtype
	}
	mydb.init()!
	return mydb
}

pub fn (mydb MyDB) set(o MyStruct) ! {
	data := mydb.serialize(o)!
	mydb.set_data(
		gid: o.gid
		objtype: mystruct.objtype
		index_int: {
			'nr':  o.nr
			'nr2': o.nr2
		}
		index_string: {
			'name':  o.name
			'color': o.color
		}
		data: data
		baseobj: o.Base
	)!
}

pub fn (mydb MyDB) get(gid smartid.GID) !MyStruct {
	data := mydb.get_data(gid)!
	return mydb.unserialize(data)
}

[params]
pub struct FindArgs {
	db.BaseFindArgs
pub mut:
	name  string
	color string
	nr    int
	nr2   int
}

pub fn (mydb MyDB) find(args FindArgs) ![]MyStruct {
	// mydb.basefind(args.BaseFindArgs) //TODO: see how to integrate the query mechanism on base into the the bigger one
	mut query_int_less := map[string]int{}
	if args.mtime_to.int() > 0 {
		query_int_less['mtime'] = args.mtime_to.int()
	}
	if args.ctime_to.int() > 0 {
		query_int_less['ctime'] = args.ctime_to.int()
	}

	mut query_int_greater := map[string]int{}
	if args.mtime_from.int() > 0 {
		query_int_greater['mtime'] = args.mtime_from.int()
	}
	if args.ctime_from.int() > 0 {
		query_int_greater['ctime'] = args.ctime_from.int()
	}

	mut query_int := map[string]int{}
	if args.nr > 0 {
		query_int['nr'] = args.nr
	}
	if args.nr2 > 0 {
		query_int['nr2'] = args.nr
	}

	mut query_str := map[string]string{}
	if args.name.len > 0 {
		query_str['name'] = args.name
	}
	if args.color.len > 0 {
		query_str['color'] = args.color
	}

	mut query_args := db.DBFindArgs{
		cid: mydb.cid
		objtype: mystruct.objtype
		query_int: query_int
		query_string: query_str
	}
	// println(query_args)
	data := db.find(query_args)!
	mut read_o := []MyStruct{}
	for d in data {
		read_o << mydb.unserialize(d)!
	}
	return read_o
}

//////////////////////serialization

// this is the method to dump binary form
pub fn (mydb MyDB) serialize(o MyStruct) ![]u8 {
	mut e := o.bin_encoder()!
	e.add_int(o.nr)
	e.add_string(o.color)
	e.add_int(o.nr2)
	e.add_list_u32(o.listu32)

	// if mydb.version==1{
	// }else if mydb.version==2{
	// 	panic("not implemented")
	// 	//json
	// 	// data:=json.encode(o)
	// 	// e.add_u8(2)//this is version 1, for binary
	// 	// e.add_string(data)
	// }else if mydb.version==3{
	// 	// e.add_u8(3)//this is version 1, for binary
	// 	//3script
	// 	panic("not implemented")
	// }else{
	// 	panic("not implemented")
	// }
	return e.data
}

// this is the method to load binary form
pub fn (mydb MyDB) unserialize(data []u8) !MyStruct {
	// mut d := encoder.decoder_new(data)
	mut d, base := db.base_decoder(data)!
	mut o := MyStruct{
		Base: base
	}
	o.nr = d.get_int()
	o.color = d.get_string()
	o.nr2 = d.get_int()
	o.listu32 = d.get_list_u32()

	// if v==1{
	// }else if v==2{
	// 	panic("not implemented")
	// 	//json
	// 	// data2:=d.get_string()
	// 	// o=json.decode(MyStruct,data2) or {MyStruct{}}
	// }else if v==3{
	// 	//3script
	// 	panic("not implemented")
	// }else{
	// 	panic("not implemented")
	// }
	return o
}
