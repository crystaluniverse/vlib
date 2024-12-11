module db

import freeflowuniverse.crystallib.core.smartid
import encoding.base32

fn table_get(mut db DB, g smartid.GID) ![]u8 {
	statement := 'SELECT data FROM ${table_name_data(db)} WHERE oid = ${g.oid()};'
	rows := db.sqlitedb.exec(statement)!

	if rows.len == 0 {
		return []u8{}
	}

	// gid identifies a record, so one record only should be returned
	if rows.len > 1 {
		return error('${rows.len} records matched the provided gid, while only one is expected')
	}

	data_str := base32.decode_string_to_string(rows[0].vals[0])!
	return data_str.bytes()
}
