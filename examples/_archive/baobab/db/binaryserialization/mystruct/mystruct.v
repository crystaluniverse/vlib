module mystruct

import freeflowuniverse.crystallib.baobab.db
import freeflowuniverse.crystallib.baobab.smartid
import freeflowuniverse.crystallib.data.paramsparser
import freeflowuniverse.crystallib.data.ourtime

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

@[params]
pub struct DBArgs {
pub mut:
	circlename string
}

pub fn db_new(args DBArgs) !MyDB {
	mut mydb := MyDB{
		circlename: args.circlename
		objtype:    'mystruct'
	}
	mydb.init()!
	return mydb
}

@[params]
pub struct MyStructArgs {
pub mut:
	params      string
	name        string
	description string
	mtime       string // modification time
	ctime       string // creation time
	nr          int
	color       string
	nr2         int
	listu32     []u32
}

pub fn (mydb MyDB) new(args MyStructArgs) !MyStruct {
	remarks := db.Remarks{
		remarks: [
			db.Remark{
				content: 'my remark content'
				time:    ourtime.now()
				rtype:   .comment
			},
			db.Remark{
				content: 'my second remark content'
				time:    ourtime.now()
				rtype:   .log
			},
		]
	}

	base := mydb.new_base(
		params:      args.params
		name:        args.name
		description: args.description
		mtime:       args.mtime
		ctime:       args.ctime
		remarks:     remarks
	)!
	mut o := MyStruct{
		Base:    base
		nr:      args.nr
		color:   args.color
		nr2:     args.nr2
		listu32: args.listu32
	}
	return o
}

pub fn (mydb MyDB) set(o MyStruct) ! {
	data := mydb.serialize(o)!
	mydb.set_data(
		gid:          o.gid
		index_int:    {
			'nr':  o.nr
			'nr2': o.nr2
		}
		index_string: {
			'name':    o.name
			'color':   o.color
			'listu32': o.listu32.map(it.str()).join(',')
		}
		data:         data
		baseobj:      o.Base
	)!
}

pub fn (mydb MyDB) get(gid smartid.GID) !MyStruct {
	data := mydb.get_data(gid)!
	return mydb.unserialize(data)
}

@[params]
pub struct FindArgs {
	db.BaseFindArgs
pub mut:
	name    ?string
	color   ?string
	nr      ?int
	nr2     ?int
	listu32 ?[]u32
}

// find on our database
//```js
// name  string
// color string
// nr    int
// nr2   int
// mtime_from ?ourtime.OurTime
// mtime_to   ?ourtime.OurTime
// ctime_from ?ourtime.OurTime
// ctime_to   ?ourtime.OurTime
// name       string
//```
pub fn (mydb MyDB) find(args FindArgs) ![]MyStruct {
	mut query_int := map[string]int{}
	if nr := args.nr {
		query_int['nr'] = nr
	}
	if nr2 := args.nr2 {
		query_int['nr2'] = nr2
	}

	mut query_string := map[string]string{}
	if name := args.name {
		query_string['name'] = name
	}
	if color := args.color {
		query_string['color'] = color
	}
	if listu32 := args.listu32 {
		query_string['listu32'] = listu32.map(it.str()).join(',')
	}

	mut query_int_less := map[string]int{}
	if ctime_to := args.ctime_to {
		query_int_less['ctime'] = ctime_to.int()
	}
	if mtime_to := args.mtime_to {
		query_int_less['mtime'] = mtime_to.int()
	}

	mut query_int_greater := map[string]int{}
	if ctime_from := args.ctime_from {
		query_int_greater['ctime'] = ctime_from.int()
	}
	if mtime_from := args.mtime_from {
		query_int_greater['mtime'] = mtime_from.int()
	}

	dbfindoargs := db.DBFindArgs{
		query_int:         query_int
		query_string:      query_string
		query_int_greater: query_int_greater
		query_int_less:    query_int_less
	}
	data := mydb.find_base(args.BaseFindArgs, dbfindoargs)!
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
	return e.data
}

// serialize to heroscript
pub fn (mydb MyDB) serialize_kwargs(o MyStruct) !map[string]string {
	mut kwargs := o.Base.serialize_kwargs()!
	kwargs['nr'] = '${o.nr}'
	kwargs['nr2'] = '${o.nr2}'
	kwargs['color'] = o.color
	mut listu32 := ''
	for i in o.listu32 {
		listu32 += '${i}, '
	}
	listu32 = listu32.trim_string_right(', ')
	kwargs['listu32'] = listu32
	return kwargs
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
	return o
}

// serialize to heroscript
pub fn (mydb MyDB) serialize_heroscript(o MyStruct) !string {
	p := paramsparser.new_from_dict(mydb.serialize_kwargs(o)!)!
	ex := p.export(
		pre:      '!!${mydb.objtype}.define '
		presort:  ['gid', 'name', 'listu32']
		postsort: ['mtime', 'ctime']
	)
	p2 := o.Base.remarks.serialize_heroscript(o.Base.gid.str())!

	return '${ex}\n${p2}'
}

pub fn (mydb MyDB) unserialize_heroscript(txt string) ![]MyStruct {
	mut res := []MyStruct{}
	for r in mydb.base_decoder_heroscript(txt)! {
		mut o := MyStruct{
			Base: r.base
		}
		p := r.params
		o.nr = p.get_int_default('nr', 0)!
		o.color = p.get_default('color', '')!
		o.nr2 = p.get_int_default('nr2', 0)!
		o.listu32 = p.get_list_u32('listu32')!
		res << o
	}
	return res
}
