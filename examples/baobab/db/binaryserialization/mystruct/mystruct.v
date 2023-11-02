module mystruct


import freeflowuniverse.crystallib.baobab.db
import freeflowuniverse.crystallib.baobab.smartid
import freeflowuniverse.crystallib.algo.encoder
import json

const objtype = 'mystruct'


pub struct MyDB {
	db.DB
}


pub struct MyStruct {
pub mut:
	gid         smartid.GID
	name        string
	nr          int
	color       string
	description string
	nr2         int
	listu32     []u32
}

[params]
pub struct DBArgs {
pub mut:
	circlename string
	version u8 = 1 //1 is bin, 2 is json, 3 is 3script
}


pub fn db_new(args DBArgs)!MyDB{
	mut mydb:= MyDB{circlename:args.circlename,version:args.version,objtype:objtype}
	mydb.init()!
	return mydb
}


pub fn  (mydb MyDB) set(o MyStruct)  ! {
	// the next will create the table if it doesn't exist yet, only checks once per mem session
	db.create(
		cid: o.gid.cid
		objtype: objtype
		index_int: ['nr', 'nr2']
		index_string: [
			'name',
			'color',
		]
	)!
	// get the serialization (v1 is a quite efficient small serialization protocol)
	data := mydb.serialize(o)
	db.set(
		gid: o.gid
		objtype: objtype
		index_int: {'nr':o.nr,'nr2':o.nr2}
		index_string: {'name':o.name'color':o.color}
		data: data
	)!
}

pub fn  (mydb MyDB)  get(gid smartid.GID) !MyStruct {
	data := db.get(gid:gid,objtype: objtype)!
	return mydb.unserialize(data)
}

pub fn  (mydb MyDB)  delete(gid smartid.GID) ! {
	db.delete(cid:mydb.cid,gid:gid,objtype:objtype)!
}

pub fn  (mydb MyDB)  delete_all() ! {
	db.delete(cid:mydb.cid,objtype:objtype)!
}


[params]
pub struct FindArgs {
pub mut:
	name        string
	color       string
	nr          int
	nr2         int
}


pub fn (mydb MyDB) find(args FindArgs) ![]MyStruct {
	mut query_int:=map[string]int{}
	if args.nr>0{
		query_int["nr"]=args.nr	
	}
	if args.nr2>0{
		query_int["nr2"]=args.nr	
	}
	mut query_str:=map[string]string{}
	if args.name.len>0{
		query_str["name"]=args.name	
	}
	if args.color.len>0{
		query_str["color"]=args.color	
	}
	mut query_args:=db.DBQueryArgs{
		cid          :mydb.cid
		objtype      : objtype
		query_int    : query_int
		query_string : query_str
	}
	// println(query_args)
	data := db.find(query_args)!
	mut read_o := []MyStruct{}
	for d in data {
		read_o << mydb.unserialize(d)
	}
	return read_o
}

//////////////////////serialization

// this is the method to dump binary form
pub fn (mydb MyDB) serialize(o MyStruct)[]u8 {
	mut e := encoder.new()
	if mydb.version==1{
		e.add_u8(1)//this is version 1, for binary
		e.add_u32(mydb.cid.u32())
		e.add_u32(o.gid.oid())
		e.add_string(o.name)
		e.add_int(o.nr)
		e.add_string(o.color)
		e.add_string(o.description)
		e.add_int(o.nr2)
		e.add_list_u32(o.listu32)
	}else if mydb.version==2{
		//json
		data:=json.encode(o)
		e.add_u8(2)//this is version 1, for binary
		e.add_string(data)
	}else if mydb.version==3{
		e.add_u8(3)//this is version 1, for binary
		//3script
		panic("not implemented")
	}else{
		panic("not implemented")
	}
	return e.data
}

// this is the method to load binary form
pub fn (mydb MyDB) unserialize(data []u8) MyStruct {
	mut o := MyStruct{}
	mut d := encoder.decoder_new(data) 
	v:=d.get_u8() //get version out
	if v==1{
		cid_int := int(d.get_u32())
		oid_int := int(d.get_u32())
		o.gid = smartid.gid(cid_int: cid_int, oid_int: oid_int)!
		o.name = d.get_string()
		o.nr = d.get_int()
		o.color = d.get_string()
		o.description = d.get_string()
		o.nr2 = d.get_int()
		o.listu32 = d.get_list_u32()
	}else if v==2{
		//json
		data2:=d.get_string()
		o=json.decode(MyStruct,data2) or {MyStruct{}}
	}else if v==3{
		//3script
		panic("not implemented")
	}else{
		panic("not implemented")
	}
	return o
}