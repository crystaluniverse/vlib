module db

import encoding.base32

// params:
// - gid smartid.GID
// - objtype string //unique type name for obj class
// - index_int map[string]int
// - index_string map[string]string
// - data []u8
// - baseobj
fn table_set(mut db DB, mut args DBSetArgs) ! {
	_, setstatements := table_set_statements(mut db, mut args)!
	db.sqlitedb.exec(setstatements)!
	// for now we just replace the data, but eventually will keep history and do content addressed
	datastr := base32.encode_to_string(args.data)
	mut datasql := 'INSERT OR REPLACE INTO ${table_name_data(db)} (oid,data) VALUES (${args.gid.oid()},\'${datastr}\');'
	db.sqlitedb.exec(datasql)!
}

fn table_set_statements(mut db DB, mut args DBSetArgs) !(string, string) {
	if args.objtype.len == 0 {
		return error('objtype needs to be specified')
	}
	mut tosetitems := ['oid']
	mut tosetvals := [args.gid.oid().str()]
	for key, val in args.index_int {
		tosetitems << '${key}'
		tosetvals << val.str()
	}
	for key, val in args.index_string {
		tosetitems << '${key}'
		tosetvals << "'${val}'"
	}
	tosetitemsstr := tosetitems.join(',').trim_right(',')
	tosetvalsstr := tosetvals.join(',').trim_right(',')

	mut setstatements := 'INSERT OR REPLACE INTO ${table_name_find(db)} (${tosetitemsstr}) VALUES (${tosetvalsstr});'

	return table_name_find(db), setstatements
}
