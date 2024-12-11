module db

import strings
import encoding.base32
import freeflowuniverse.crystallib.ui.console

// [params]
// pub struct DBFindArgs {
// pub mut:
// 	cid               smartid.CID
// 	objtype           string
// 	query_int         map[string]int
// 	query_string      map[string]string
// 	query_int_less    map[string]int
// 	query_int_greater map[string]int
// }
// return list of data blocks which then need to be deserialized based on the DBFindArgs
fn table_find(db DB, args DBFindArgsI) ![][]u8 {
	sql_statement_find := sql_build_find(db, args)
	// console.print_debug('find sql: ${sql_statement_find}')
	mut oids := []int{}

	rows := db.sqlitedb.exec(sql_statement_find)!
	if rows.len == 0 {
		return [][]u8{}
	}

	for _, row in rows {
		if row.vals.len != 1 {
			panic('invalid record, row must consist of  oid only, ${row} is returned')
		}
		oids << row.vals[0].int()
	}

	sql_statement_multiget := sql_build_multiget(db, oids)
	data_rows := db.sqlitedb.exec(sql_statement_multiget)!
	mut data := [][]u8{}
	for _, data_row in data_rows {
		data_str := base32.decode_string_to_string(data_row.vals[0])!
		data << data_str.bytes()
	}
	return data
}

// build sql statement based on DBFindArgs
fn sql_build_find(db DB, args DBFindArgsI) string {
	mut b := strings.new_builder(15)
	b.write_string('SELECT oid FROM ${table_name_find(db)} WHERE ')

	for k, v in args.query_int_less {
		b.write_string('${k} < ${v} AND')
	}

	for k, v in args.query_int_greater {
		b.write_string('${k} > ${v} AND')
	}

	for k, v in args.query_int {
		b.write_string('${k} = ${v} AND')
	}

	for k, v in args.query_string {
		b.write_string('${k} = \'${v}\' AND')
	}

	mut str := b.str()
	str = str.trim_string_right('AND')
	str = str.trim_string_right('WHERE ')

	return str
}

fn sql_build_multiget(db DB, oids []int) string {
	mut b := strings.new_builder(20)
	b.write_string('SELECT data FROM ${table_name_data(db)} WHERE oid IN (')
	for id in oids {
		b.write_string('${id}, ')
	}
	b.cut_last(2)
	b.write_string(' );')
	return b.str()
}
