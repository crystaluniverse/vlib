module db

import freeflowuniverse.crystallib.core.smartid

fn table_delete(mut mydb DB, args DBDeleteArgs) ! {
	if mydb.sql_table_exist(table_name_find(mydb))! {
		mydb.sql_exec_one(table_delete_statement(table_name_find(mydb), args))!
	}
	if mydb.sql_table_exist(table_name_data(mydb))! {
		mydb.sql_exec_one(table_delete_statement(table_name_data(mydb), args))!
	}
}

fn table_delete_statement(name string, args DBDeleteArgs) string {
	gid := args.gid or { smartid.GID{} }
	oid := gid.oid()
	q := if oid > 0 {
		'DELETE from ${name} WHERE oid = ${oid};'
	} else {
		'DELETE from ${name};'
	}
	return q
}
