module db

// import freeflowuniverse.crystallib.data.paramsparser
// import freeflowuniverse.crystallib.algo.encoder
import freeflowuniverse.crystallib.baobab.smartid
import freeflowuniverse.crystallib.data.ourtime
// import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.data.actionsparser
import freeflowuniverse.crystallib.data.paramsparser

[params]
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
fn (mut a DBFindArgs) complete(args BaseFindArgs) ! {
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

[params]
pub struct BaseFindArgs {
pub mut:
	mtime_from ?ourtime.OurTime
	mtime_to   ?ourtime.OurTime
	ctime_from ?ourtime.OurTime
	ctime_to   ?ourtime.OurTime
	name       string
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
	args.complete(base_args)! // this fills in the base_args into the other args
	args.cid = db.cid
	args.objtype = db.objtype
	return find(args)!
}

pub struct DecoderActionItem {
pub:
	base   Base
	params paramsparser.Params
}

pub fn (db DB) base_decoder_3script(txt string) ![]DecoderActionItem {
	mut res := []DecoderActionItem{}
	mut remarks := map[string][]paramsparser.Params{} // key is the gid of the base obj

	mut parser := actionsparser.new(defaultcircle: 'aaa', text: txt)!
	actions := parser.filtersort(actor: db.objtype)!
	actions_remarks := parser.filtersort(actor: 'remark')!

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
			o.gid = smartid.gid(gid_str: p.get_default('gid', '')!)!
			o.params = paramsparser.new(p.get_default('params', '')!)!
			o.name = p.get_default('name', '')!
			o.description = p.get_default('description', '')!
			// TODO: check gid is not empty

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
