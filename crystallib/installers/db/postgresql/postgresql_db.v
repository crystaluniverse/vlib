module postgresql

import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.texttools
import db.pg
import os
import net

pub fn (mut server Postgresql) path_config() !pathlib.Path {
	return pathlib.get_dir(path: '${server.path}/config', create: true)!
}

pub fn (mut server Postgresql) path_data() !pathlib.Path {
	return pathlib.get_dir(path: '${server.path}/data', create: true)!
}

pub fn (mut server Postgresql) path_export() !pathlib.Path {
	return pathlib.get_dir(path: '${server.path}/exports', create: true)!
}

fn is_port_open(host string, port int) bool {
	mut socket := net.dial_tcp('${host}:${port}') or { return false }
	socket.close() or { return false }
	return true
}

pub fn (mut server Postgresql) db() !pg.DB {
	if is_port_open('localhost', 5432) == false {
		return error('PostgreSQL is not listening on port 5432')
	}

	conn_string := 'postgresql://root:${server.passwd}@localhost:5432/postgres?connect_timeout=5'
	mut db := pg.connect_with_conninfo(conn_string)!
	// console.print_header("Database connected: ${db}")
	return db
}

pub fn (mut server Postgresql) check() ! {
	mut db := server.db() or { return error('failed to check server: ${err}') }

	db.exec('SELECT version();') or { return error('postgresql could not do select version') }

	cmd := 'podman healthcheck run ${server.name}'
	result := os.execute(cmd)

	if result.exit_code != 0 {
		return error("Postgresql container isn't healthy: ${result.output}")
	}

	container_id := 'podman container inspect default --format {{.Id}}'
	container_id_result := os.execute(container_id)
	if container_id_result.exit_code != 0 {
		return error('Cannot get the container ID: ${result.output}')
	}

	server.container_id = container_id
	console.print_header('Container ID: ${container_id_result.output}')
}

pub fn (mut server Postgresql) db_exists(name_ string) !bool {
	mut db := server.db()!
	// SELECT datname FROM pg_database WHERE datname='gitea';
	r := db.exec("SELECT datname FROM pg_database WHERE datname='${name_}';")!
	if r.len == 1 {
		console.print_header('db exists: ${name_}')
		return true
	}
	if r.len > 1 {
		return error('should not have more than 1 db with name ${name_}')
	}
	return false
}

pub fn (mut server Postgresql) db_create(name_ string) ! {
	name := texttools.name_fix(name_)
	server.check()!
	mut db := server.db()!
	db_exists := server.db_exists(name_)!
	if !db_exists {
		console.print_header('db create: ${name_}')
		db.exec('CREATE DATABASE ${name};')!
	}
	db_exists2 := server.db_exists(name_)!
	if !db_exists2 {
		return error('Could not create db: ${name_}, could not find in DB.')
	}
}

pub fn (mut server Postgresql) db_delete(name_ string) ! {
	name := texttools.name_fix(name_)
	server.check()!
	mut db := server.db()!
	db_exists := server.db_exists(name_)!
	if db_exists {
		console.print_header('db delete: ${name_}')
		db.exec('DROP DATABASE ${name};')!
	}
	db_exists2 := server.db_exists(name_)!
	if db_exists2 {
		return error('Could not delete db: ${name_}, could not find in DB.')
	}
}
