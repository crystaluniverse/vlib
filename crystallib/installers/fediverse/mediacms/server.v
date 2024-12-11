module mediacms

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.osal.zinit
import freeflowuniverse.crystallib.data.dbfs
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.installers.postgresql
import json
import rand
import os
import time
import freeflowuniverse.crystallib.ui.console

pub struct Server {
pub mut:
	name        string
	config      Config
	process     ?zinit.ZProcess
	path_config pathlib.Path
}

// get the server of type mediacms
//```js
// name        string = 'default'
// path        string = '/data/mediacms'
// passwd      string
//```
// if name exists already in the config DB, it will load for that name
pub fn server_new(myconfig_ Config) !Server {
	mut myconfig := myconfig_
	if myconfig.passwd == '' {
		myconfig.passwd = rand.string(12)
	}
	myconfig.name = texttools.name_fix(myconfig.name)
	key := 'mediacms_config_${myconfig.name}'
	mut kvs := dbfs.new(name: 'config')!
	if myconfig.reset || !kvs.exists(key) {
		data := json.encode(myconfig)
		kvs.set(key, data)!
	}
	return server_get(myconfig.name)!
}

pub fn server_get(name_ string) !Server {
	name := texttools.name_fix(name_)
	console.print_header('get mediacms server ${name}')
	key := 'mediacms_config_${name}'
	mut kvs := dbfs.new(name: 'config')!
	if kvs.exists(key) {
		data := kvs.get(key)!
		myconfig := json.decode(Config, data)!

		mut server := Server{
			name: name
			config: myconfig
			path_config: pathlib.get_dir(path: '${myconfig.dest}/cfg', create: true)!
		}

		mut z := zinit.new()!
		processname := 'mediacms_${name}'
		if z.process_exists(processname) {
			server.process = z.process_get(processname)!
		}
		// console.print_debug(" - server get ok")
		server.start()!
		return server
	}
	return error("can't find server mediacms with name ${name}")
}

// return status
// ```
// pub enum ZProcessStatus {
//     unknown
//     init
//     ok
//     error
//     blocked
//     spawned
// }
// ```
pub fn (mut server Server) status() zinit.ZProcessStatus {
	mut process := server.process or { return .unknown }
	return process.status() or { return .unknown }
}

// run mediacms as docker compose
pub fn (mut server Server) start() ! {
	console.print_header('start mediacms: ${server.name}')
	mut db := postgresql.get(server.config.postgresql_name)!

	// now create the DB
	db.db_create('mediacms')!

	// mut z := zinit.new()!
	// processname := 'mediacms_${server.name}'
	// mut p := z.process_new(
	//     name: processname
	//     cmd: '
	//     cd ${server.path_config.path}
	//     mediacms
	//     '
	// )!

	// p.output_wait('Starting external listener on :8008', 120)!

	// o := p.log()!
	// console.print_debug(o)

	// server.check()!

	console.print_header('mediacms start ok.')
}

pub fn (mut server Server) restart() ! {
	server.stop()!
	server.start()!
}

pub fn (mut server Server) stop() ! {
	print_backtrace()
	console.print_header('stop mediacms: @{server.name}')
	mut process := server.process or { return }
	return process.stop()
}

// check health, return true if ok
pub fn (mut server Server) check() ! {
	mut p := server.process or { return error("can't find process for server.") }
	p.check()!
	// TODO: need to do some other checks to mediacms e.g. rest calls
}

// check health, return true if ok
pub fn (mut server Server) ok() bool {
	server.check() or { return false }
	return true
}

// remove all data
pub fn (mut server Server) destroy() ! {
	server.stop()!
	server.path_config.delete()!
}
