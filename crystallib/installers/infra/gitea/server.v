module gitea

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
	path            string = '/data/gitea'
	passwd          string
	postgresql_name string = 'default'
	mail_from       string = 'git@meet.tf'
	smtp_addr       string = 'smtp-relay.brevo.com'
	smtp_login      string @[required]
	smpt_port       int = 587
	smtp_passwd     string
	domain          string @[required]
	jwt_secret      string
	lfs_jwt_secret  string
	internal_token  string
	secret_key      string
}

pub struct Server {
pub mut:
	name        string
	config      Config
	process     ?zinit.ZProcess
	path_config pathlib.Path
}

// get the gitea server
//```js
// name        string = 'default'
// path        string = '/data/gitea'
// passwd      string
//```
// if name exists already in the config DB, it will load for that name
pub fn new(args_ Config) !Server {
	install()! // make sure it has been build & ready to be used
	mut args := args_
	if args.passwd == '' {
		args.passwd = rand.string(12)
	}
	args.name = texttools.name_fix(args.name)
	key := 'gitea_config_${args.name}'
	mut kvs := dbfs.new(name: 'config')!
	if !kvs.exists(key) {
		// jwt_secret        string
		// lfs_jwt_secret    string
		// internal_token    string
		// secret_key        string

		if args.jwt_secret == '' {
			r := os.execute_or_panic('gitea generate secret JWT_SECRET')
			args.jwt_secret = r.output.trim_space()
		}
		if args.lfs_jwt_secret == '' {
			r := os.execute_or_panic('gitea generate secret LFS_JWT_SECRET')
			args.lfs_jwt_secret = r.output.trim_space()
		}
		if args.internal_token == '' {
			r := os.execute_or_panic('gitea generate secret INTERNAL_TOKEN')
			args.internal_token = r.output.trim_space()
		}
		if args.secret_key == '' {
			r := os.execute_or_panic('gitea generate secret SECRET_KEY')
			args.secret_key = r.output.trim_space()
		}

		data := json.encode(args)
		kvs.set(key, data)!
	}
	return get(args.name)!
}

pub fn get(name_ string) !Server {
	console.print_header('get gitea server ${name_}')
	name := texttools.name_fix(name_)
	key := 'gitea_config_${name}'
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
		processname := 'gitea_${name}'
		if z.process_exists(processname) {
			server.process = z.process_get(processname)!
		}
		// console.print_debug(" - server get ok")
		server.start()!
		return server
	}
	return error("can't find server gitea with name ${name}")
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

// run gitea as docker compose
pub fn (mut server Server) start() ! {
	// if server.ok(){
	// 	return
	// }

	console.print_header('start gitea: ${server.name}')
	mut db := postgresql.get(server.config.postgresql_name)!

	// now create the DB
	db.db_create('gitea')!

	// if true{
	// 	panic("sd")
	// }

	// TODO: postgresql can be on other server, need to fill in all arguments in template
	t1 := $tmpl('templates/app.ini')
	mut config_path := server.path_config.file_get_new('app.ini')!
	config_path.write(t1)!

	osal.user_add(name: 'git')!

	osal.exec(
		cmd: '
		chown -R  git:root ${server.config.path}
		chmod -R 777 /usr/local/bin
		'
	)!

	mut z := zinit.new()!
	processname := 'gitea_${server.name}'
	mut p := z.process_new(
		name: processname
		cmd: '
		cd /tmp
		sudo -u git bash -c \'gitea web --config ${config_path.path} --verbose\'
		'
	)!

	p.output_wait('Starting new Web server: tcp:0.0.0.0:3000', 120)!

	o := p.log()!
	console.print_debug(o)

	server.check()!

	console.print_header('gitea start ok.')
}

pub fn (mut server Server) restart() ! {
	server.stop()!
	server.start()!
}

pub fn (mut server Server) stop() ! {
	print_backtrace()
	console.print_header('stop gitea: ${server.name}')
	mut process := server.process or { return }
	return process.stop()
}

// check health, return true if ok
pub fn (mut server Server) check() ! {
	mut p := server.process or { return error("can't find process for server.") }
	p.check()!
	// TODO: need to do some other checks to gitea e.g. rest calls
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
