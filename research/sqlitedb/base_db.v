module db

// import freeflowuniverse.crystallib.data.paramsparser
// import freeflowuniverse.crystallib.data.encoder
import freeflowuniverse.crystallib.core.smartid
import freeflowuniverse.crystallib.data.ourtime
// import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.core.playbook
import freeflowuniverse.crystallib.data.paramsparser

@[params]
pub struct DBBaseNewArgs {
pub mut:
	params      string
	name        string
	description string
	mtime       string // modification time
	ctime       string // creation time
	remarks     Remarks
}

//```
// params             string
// name               string
// description        string
// mtime              string// modification time
// ctime              string // creation time
//```
pub fn (db DB) new_base(args DBBaseNewArgs) !Base {
	b := Base{
		gid: smartid.gid(cid_str: db.cid.str())!
		params: paramsparser.new(args.params)!
		name: args.name
		description: args.description
		mtime: ourtime.new(args.mtime)!
		ctime: ourtime.new(args.ctime)!
		remarks: args.remarks
	}
	return b
}

@[params]
pub struct DBSetArgs {
pub mut:
	gid          smartid.GID
	objtype      string // unique type name for obj class
	index_int    map[string]int
	index_string map[string]string
	data         []u8 // if empty will do json
	baseobj      Base
}

// set data in database, need to pass the base obj as well
// ```js
// gid          smartid.GID
// objtype      string // unique type name for obj class
// index_int    map[string]int
// index_string map[string]string
// data         []u8 // if empty will do json
// baseobj      Base
// ```
pub fn (db DB) set_data(args_ DBSetArgs) ! {
	// create the table if it doesn't exist yet
	mut args := args_

	args.baseobj.mtime.check() // make sure time is filled in
	args.baseobj.ctime.check() // make sure time is filled in

	args.index_int['mtime'] = args.baseobj.mtime.int()
	args.index_int['ctime'] = args.baseobj.ctime.int()
	args.index_string['name'] = args.baseobj.name

	create(
		cid: db.cid
		objtype: db.objtype
		index_int: args.index_int.keys()
		index_string: args.index_string.keys()
	)!
	set(
		gid: args.gid
		objtype: db.objtype
		index_int: args.index_int
		index_string: args.index_string
		data: args.data
	)!
}

pub fn (db DB) get_data(gid smartid.GID) ![]u8 {
	data := get(gid: gid, objtype: db.objtype)!
	return data
}

pub fn (db DB) delete(gid smartid.GID) ! {
	delete(cid: db.cid, gid: gid, objtype: db.objtype)!
}

pub fn (db DB) delete_all() ! {
	delete(cid: db.cid, objtype: db.objtype)!
}

// add the basefind args to the generic dbfind args .
// complete the missing statements in basefind args
fn (mut a DBFindArgsI) complete(args BaseFindArgs) ! {
	if args.name.len > 0 {
		a.query_string['name'] = args.name
	}
	mtime_from := args.mtime_from or { ourtime.OurTime{} }
	mtime_to := args.mtime_from or { ourtime.OurTime{} }
	ctime_from := args.mtime_from or { ourtime.OurTime{} }
	ctime_to := args.mtime_from or { ourtime.OurTime{} }

	if !mtime_from.empty() {
		a.query_int_greater['mtime'] = mtime_from.int()
	}
	if !mtime_to.empty() {
		a.query_int_less['mtime'] = mtime_from.int()
	}
	if !ctime_from.empty() {
		a.query_int_greater['ctime'] = mtime_from.int()
	}
	if !ctime_to.empty() {
		a.query_int_less['ctime'] = mtime_from.int()
	}
}

@[params]
pub struct BaseFindArgs {
pub mut:
	mtime_from ?ourtime.OurTime
	mtime_to   ?ourtime.OurTime
	ctime_from ?ourtime.OurTime
	ctime_to   ?ourtime.OurTime
	name       string
}

@[params]
pub struct DBFindArgs {
pub mut:
	query_int         map[string]int
	query_string      map[string]string
	query_int_less    map[string]int
	query_int_greater map[string]int
}

// find data based on find statements
// there are 2 parts to make up the find
// BaseFindArgs
//```js
// mtime_from ?ourtime.OurTime
// mtime_to   ?ourtime.OurTime
// ctime_from ?ourtime.OurTime
// ctime_to   ?ourtime.OurTime
// name       string
//```
// DBFindArgs, is the more generic part .
//```js
// query_int         map[string]int
// query_string      map[string]string
// query_int_less    map[string]int
// query_int_greater map[string]int
//```
pub fn (db DB) find_base(base_args BaseFindArgs, args_ DBFindArgs) ![][]u8 {
	mut args := args_
	// remove the empty ones, TODO: can't this be done more elegant?
	mut toremove := []string{}
	for key, val in args.query_string {
		if val == '' {
			toremove << key
		}
	}
	for t in toremove {
		args.query_string.delete(t)
	}
	mut toremove2 := []string{}
	for key, val in args.query_int {
		if val == 0 {
			toremove2 << key
		}
	}
	for t in toremove2 {
		args.query_int.delete(t)
	}
	mut argsi := DBFindArgsI{
		cid: db.cid
		objtype: db.objtype
		query_int: args.query_int
		query_string: args.query_string
		query_int_less: args.query_int_less
		query_int_greater: args.query_int_greater
	}
	argsi.complete(base_args)! // this fills in the base_args into the other args
	return find(argsi)!
}

pub struct DecoderActionItem {
pub:
	base   Base
	params paramsparser.Params
}

pub fn (db DB) base_decoder_heroscript(txt string) ![]DecoderActionItem {
	mut res := []DecoderActionItem{}
	mut remarks := map[string][]paramsparser.Params{} // key is the gid of the base obj

	mut parser := playbook.new(text: txt)!
	actions := parser.find(filter: '${db.objtype}:*')!
	actions_remarks := parser.find(filter: 'remark:*')!

	for action in actions_remarks {
		if action.name == 'define' {
			// now we are in remark define
			gid_str := action.params.get_default('gid', '')!
			if gid_str.len > 0 {
				gid := smartid.gid(gid_str: gid_str)!
				if gid.str() !in remarks {
					remarks[gid.str()] = []paramsparser.Params{}
				}
				remarks[gid.str()] << action.params // get all remarks per gid
			}
		}
	}
	for action in actions {
		if action.name == 'define' {
			// now we will find the rootobject define action
			mut p := action.params
			mut o := Base{}
			o.gid = smartid.gid(gid_str: p.get('gid')!)!
			o.params = paramsparser.new(p.get_default('params', '')!)!
			o.name = p.get_default('name', '')!
			o.description = p.get_default('description', '')!
			o.mtime = ourtime.new(p.get('mtime')!)!
			o.ctime = ourtime.new(p.get('ctime')!)!

			// now find all remarks who are linked to this obj
			if o.gid.str() in remarks {
				for remarkparam in remarks[o.gid.str()] {
					remark := remark_unserialize_params(remarkparam)!
					o.remarks.remarks << remark
				}
			}
			res << DecoderActionItem{
				base: o
				params: p
			}
		}
	}
	return res
}
