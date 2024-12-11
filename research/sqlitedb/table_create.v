module db

import freeflowuniverse.crystallib.ui.console

fn index_exists(mut db DB, name string) bool {
	r := db.sqlitedb.exec("
    	SELECT 1 FROM sqlite_master
    	WHERE type='index' AND name='${name}_index' AND tbl_name='${name}'
		") or {
		return false
	}
	if r.len > 0 {
		return true
	}
	return false
}

fn tables_create(mut db DB, mut args DBTableCreateArgs) ! {
	if args.objtype.len == 0 {
		return error('objtype needs to be specified')
	}
	if 'oid' !in args.index_int {
		args.index_int << 'oid'
	}
	mut datatable := 'CREATE TABLE IF NOT EXISTS ${table_name_data(db)} (\n'
	datatable += 'data BLOB,\n'
	datatable += 'oid INTEGER PRIMARY KEY'
	datatable += ');\n'
	// console.print_debug(datatable)
	db.sql_exec_one(datatable)!

	if !(index_exists(mut db, table_name_data(db))) {
		datatable_index := 'CREATE INDEX ${table_name_data(db)}_index ON ${table_name_data(db)} (oid);'
		db.sql_exec_one(datatable_index)!
	}

	// NOW CREATE THE TABLES FOR FIND
	tablename := table_name_find(db)
	mut searchtable := 'CREATE TABLE IF NOT EXISTS ${tablename} (\n'
	mut toindex := []string{}
	for key in args.index_int {
		searchtable += '${key} INTEGER,\n'
		toindex << key
	}
	for key in args.index_string {
		searchtable += '${key} STRING,\n'
		toindex << key
	}
	searchtable = searchtable.trim_right(' \n,')
	searchtable += '\n);\n'

	toindexstr := toindex.join(',').trim_right(',')

	indexsql := 'CREATE INDEX ${tablename}_index ON ${tablename} (${toindexstr})'
	db.sqlitedb.exec(searchtable)!
	if !(index_exists(mut db, tablename)) {
		db.sql_exec_one(indexsql)!
	}

	return
}
