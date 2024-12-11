module db

import freeflowuniverse.crystallib.ui.console

fn table_name_find(db DB) string {
	tablename := '${db.objtype}_find'
	return tablename
}

fn table_name_data(db DB) string {
	tablename := '${db.objtype}_data'
	return tablename
}

fn (mydb DB) sql_exec_one(statement string) ! {
	// console.print_debug("DB:${mydb.objtype}")
	// console.print_debug(statement)
	mydb.sqlitedb.exec(statement)!
	// if rc>0{
	// 	return error("Could not execute ($rc): ${statement}")
	// }
}

fn (mydb DB) sql_table_exist(name string) !bool {
	q := "SELECT name FROM sqlite_master WHERE type='table' AND name='${name}'"
	r := mydb.sqlitedb.exec(q)!
	if r.len > 0 {
		// console.print_debug(" table $name exists")
		return true
	}
	// console.print_debug(" table $name does NOT exists")
	return false
}
