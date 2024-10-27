module backend

import db.sqlite
import db.pg
import freeflowuniverse.crystallib.servers.postgres

pub struct Row {
pub mut:
	vals []string
}

pub struct Database {
pub mut:
	default_db DatabaseType
	sqlite_db ?sqlite.DB
	postgres_db ?pg.DB
}

pub enum DatabaseType {
	sqlite
	postgres
}

@[params]
pub struct ExecParams {
	db_type DatabaseType
}

fn (mut db Database) exec(cmd string, params ExecParams) ![]Row {
	rows := match params.db_type {
		.sqlite {
			rows_ := db.sqlite_db or {panic('err')}.exec(cmd)!
			rows_.map(Row{vals: it.vals})
		}
		.postgres {
			rows_ := db.postgres_db or {panic('err')}.exec(cmd)!
			rows_.map(Row{vals: it.vals.map(it or {''})})
		}
	}
	return rows
}

fn (mut db Database) insert(object RootObject) ![]Row {
	indices, values := object.sql_indices_values()
	println('debugzo1')
	rows := match db.default_db {
		.sqlite {
			rows_ := db.sqlite_db or {panic('err')}.exec("INSERT INTO ${get_table_name(object)} (${indices.join(', ')}) VALUES (${values.join(', ')})")!
			rows_.map(Row{vals: it.vals})
		}
		.postgres {
			mut params := []string{}
			for i, _ in indices {
				params << '\$${i+1}'
			}
			println("debb INSERT INTO ${get_table_name(object)} (${indices.join(', ')}) VALUES (${values.join(', ')})")
			rows_ := db.postgres_db or {panic('err')}.exec("INSERT INTO ${get_table_name(object)} (${indices.join(', ')}) VALUES (${values.join(', ')})") or { panic(err) }
			rows_.map(Row{vals: it.vals.map(it or {''})})
		}
	}
	println('debugzo2')
	return rows
}