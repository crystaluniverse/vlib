module zitadel

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

@[params]
pub struct Config {
pub mut:
	name            string = 'default'
	reset           bool
	path            string = '/data/zitadel'
	passwd          string @[required]
	secret          string
	postgresql_name string = 'default'
	mail_from       string = 'git@meet.tf'
	smtp_addr       string = 'smtp-relay.brevo.com'
	smtp_login      string @[required]
	smpt_port       int = 587
	smtp_passwd     string
	domain          string @[required]
	orgname         string = 'default'
}

pub struct Server {
pub mut:
	name        string
	config      Config
	process     ?zinit.ZProcess
	path_config pathlib.Path
}

// get the zitadel server
//```js
// name           	  string = "default"
// reset             bool
// path              string = '/data/zitadel'
// passwd            string
// postgresql_name   string = "default"
// mail_from         string = 'git@meet.tf'
// smtp_addr         string = 'smtp-relay.brevo.com'
// smtp_login	      string @[required]
// smpt_port         int = 587
// smtp_passwd       string
// domain			  string @[required]
//```
// if name exists already in the config DB, it will load for that name
pub fn new(args_ Config) !Server {
	install()! // make sure it has been build & ready to be used
	mut args := args_
	if args.secret == '' {
		args.secret = rand.string(32)
	}
	args.name = texttools.name_fix(args.name)
	key := 'zitadel_config_${args.name}'
	mut kvs := dbfs.new(name: 'config')!
	if args.reset || !kvs.exists(key) {
		data := json.encode(args)
		kvs.set(key, data)!
	}
	return get(args.name)!
}

pub fn get(name_ string) !Server {
	console.print_header('get zitadel server ${name_}')
	name := texttools.name_fix(name_)
	key := 'zitadel_config_${name}'
	mut kvs := dbfs.new(name: 'config')!
	if kvs.exists(key) {
		data := kvs.get(key)!
		args := json.decode(Config, data)!

		mut server := Server{
			name: name
			config: args
			path_config: pathlib.get_dir(path: '${args.path}/cfg', create: true)!
		}

		mut z := zinit.new()!
		processname := 'zitadel_${name}'
		if z.process_exists(processname) {
			server.process = z.process_get(processname)!
		}
		// console.print_debug(" - server get ok")
		server.start()!
		return server
	}
	return error("can't find server zitadel with name ${name}")
}

// return status
// ```
// pub enum ZProcessStatus {
// 	unknown
// 	init
// 	ok
// 	error
// 	blocked
// 	spawned
// }
// ```
pub fn (mut server Server) status() zinit.ZProcessStatus {
	mut process := server.process or { return .unknown }
	return process.status() or { return .unknown }
}

// run zitadel as docker compose
pub fn (mut server Server) start() ! {
	// if server.ok(){
	// 	return
	// }

	console.print_header('start zitadel: ${server.name}')
	mut db := postgresql.get(server.config.postgresql_name)!

	console.print_debug(db)

	if server.config.reset {
		db.db_delete('zitadel')!
	}

	// now create the DB
	db.db_create('zitadel')!

	// if true{
	// 	panic("sd")
	// }

	t1 := $tmpl('templates/defaults.yaml')
	mut config_path := server.path_config.file_get_new('defaults.yaml')!
	config_path.write(t1)!

	// mut z := zinit.new()!
	// processname:='zitadel_${server.name}'
	// mut p := z.process_new(
	// 	name: processname
	// 	cmd: '
	// 	cd /tmp
	// 	export ZITADEL_EXTERNALSECURE=false
	// 	zitadel start-from-init --config ${config_path.path} --masterkey "${server.config.secret}" --tlsMode disabled
	// 	'
	// )!

	// p.stop()!

	// p.output_wait("Starting new Web server: tcp:0.0.0.0:3000",120)!

	// o:=p.log()!
	// console.print_debug(o)

	// server.check()!

	// console.print_debug(" - zitadel start ok.")
}

pub fn (mut server Server) restart() ! {
	server.stop()!
	server.start()!
}

pub fn (mut server Server) stop() ! {
	// print_backtrace()
	console.print_header('stop zitadel: ${server.name}')
	mut process := server.process or { return }
	return process.stop()
}

// check health, return true if ok
pub fn (mut server Server) check() ! {
	mut p := server.process or { return error("can't find process for server.") }
	p.check()!
	// TODO: need to do some other checks to zitadel e.g. rest calls
}

// check health, return true if ok
pub fn (mut server Server) ok() bool {
	server.check() or { return false }
	return true
}

// remove all data
pub fn (mut server Server) destroy() ! {
	mut process := server.process or { panic('didnt find process') }
	process.destroy()!
	server.path_config.delete()!
	mut db := postgresql.get(server.config.postgresql_name)!
	db.db_delete('zitadel')!
}
