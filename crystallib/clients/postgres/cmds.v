module postgres

import db.pg
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.osal
import os
import freeflowuniverse.crystallib.ui.console

pub fn (mut self PostgresClient[Config]) check() ! {
	mut db := self.db
	db.exec('SELECT version();') or { return error('can\t select version from database.\n${self}') }
}

pub fn (mut self PostgresClient[Config]) exec(c_ string) ![]pg.Row {
	mut db := self.db
	mut c := c_
	if !(c.trim_space().ends_with(';')) {
		c += ';'
	}

	config := self.config()!
	return db.exec(c) or {
		return error('can\t execute query on ${config.host}:${config.dbname}.\n${c}\n${err}')
	}
}

pub fn (mut self PostgresClient[Config]) db_exists(name_ string) !bool {
	mut db := self.db
	r := db.exec("SELECT datname FROM pg_database WHERE datname='${name_}';")!
	if r.len == 1 {
		// console.print_header(' db exists: ${name_}')
		return true
	}
	if r.len > 1 {
		return error('should not have more than 1 db with name ${name_}')
	}
	return false
}

pub fn (mut self PostgresClient[Config]) db_create(name_ string) ! {
	name := texttools.name_fix(name_)
	mut db := self.db
	db_exists := self.db_exists(name_)!
	if !db_exists {
		console.print_header(' db create: ${name}')
		db.exec('CREATE DATABASE ${name};')!
	}
	db_exists2 := self.db_exists(name_)!
	if !db_exists2 {
		return error('Could not create db: ${name_}, could not find in DB.')
	}
}

pub fn (mut self PostgresClient[Config]) db_delete(name_ string) ! {
	mut db := self.db
	name := texttools.name_fix(name_)
	self.check()!
	db_exists := self.db_exists(name_)!
	if db_exists {
		console.print_header(' db delete: ${name_}')
		db.exec('DROP DATABASE ${name};')!
	}
	db_exists2 := self.db_exists(name_)!
	if db_exists2 {
		return error('Could not delete db: ${name_}, could not find in DB.')
	}
}

pub fn (mut self PostgresClient[Config]) db_names() ![]string {
	mut res := []string{}
	sqlstr := "SELECT datname FROM pg_database WHERE datistemplate = false and datname != 'postgres' and datname != 'root';"
	for row in self.exec(sqlstr)! {
		v := row.vals[0] or { '' }
		res << v or { '' }
	}
	return res
}

@[params]
pub struct BackupParams {
pub mut:
	dbname string
	dest   string
}

pub fn (mut self PostgresClient[Config]) backup(args BackupParams) ! {
	if args.dest == '' {
		return error('specify the destination please')
	}
	if !os.exists(args.dest) {
		os.mkdir_all(args.dest)!
	}

	if args.dbname == '' {
		for dbname in self.db_names()! {
			self.backup(dbname: dbname, dest: args.dest)!
		}
	} else {
		config := self.config()!
		cmd := '
			export PGPASSWORD=\'${config.password}\'
			pg_dump -h ${config.host} -p ${config.port} -U ${config.user} --dbname=${args.dbname} --format=c > "${args.dest}/${args.dbname}.bak"
			'
		// console.print_debug(cmd)
		osal.exec(cmd: cmd, stdout: true)!
	}
}
