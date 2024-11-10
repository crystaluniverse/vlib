module dendrite

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
	name                       string = 'default'
	reset                      bool
	path                       string = '/data/dendrite'
	passwd                     string @[required]
	postgresql_name            string = 'default'
	domain                     string @[required]
	registration_shared_secret string @[required]
	recaptcha_public_key       string @[required]
	recaptcha_private_key      string @[required]
	recaptcha_bypass_secret    string @[required]
}

pub struct Server {
pub mut:
	name        string
	config      Config
	process     ?zinit.ZProcess
	path_config pathlib.Path
}

// get the dendrite server
//```js
// name        string = 'default'
// path        string = '/data/dendrite'
// passwd      string
//```
// if name exists already in the config DB, it will load for that name
pub fn new(args_ Config) !Server {
	install(reset: args_.reset)! // make sure it has been build & ready to be used
	mut args := args_
	if args.passwd == '' {
		args.passwd = rand.string(12)
	}
	args.name = texttools.name_fix(args.name)
	key := 'dendrite_config_${args.name}'
	mut kvs := dbfs.new(name: 'config')!
	if args.reset || !kvs.exists(key) {
		data := json.encode_pretty(args)
		kvs.set(key, data)!
	}
	return get(args.name)!
}

pub fn get(name_ string) !Server {
	console.print_header('get dendrite server ${name_}')
	name := texttools.name_fix(name_)
	key := 'dendrite_config_${name}'
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
		processname := 'dendrite_${name}'
		if z.process_exists(processname) {
			server.process = z.process_get(processname)!
		}
		// console.print_debug(" - server get ok")
		server.start()!
		return server
	}
	return error("can't find server dendrite with name ${name}")
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

// run dendrite as docker compose
pub fn (mut server Server) start() ! {
	console.print_header('start dendrite: ${server.name}')
	mut db := postgresql.get(server.config.postgresql_name)!

	// now create the DB
	db.db_create('dendrite')!

	t1 := $tmpl('templates/dendrite.yaml').replace('??', '@')
	mut config_path := server.path_config.file_get_new('dendrite.yaml')!
	config_path.write(t1)!

	kpath1 := '${server.path_config.path}/matrix_key.pem'
	if !os.exists(kpath1) {
		osal.exec(cmd: 'dendrite-generate-keys --private-key ${kpath1}')!
	}

	keyspath := '/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${server.config.domain}'
	if !os.exists(keyspath) {
		return error('cannot find letsencrypt keys for caddy in: ${keyspath}')
	}

	os.cp('${keyspath}/${server.config.domain}.crt', '${server.path_config.path}/server.crt')!
	os.cp('${keyspath}/${server.config.domain}.key', '${server.path_config.path}/server.key')!

	mut z := zinit.new()!
	processname := 'dendrite_${server.name}'
	mut p := z.process_new(
		name: processname
		cmd: '
		cd ${server.path_config.path}
		dendrite
		'
	)!

	p.output_wait('Starting external listener on :8008', 120)!

	o := p.log()!
	console.print_debug(o)

	server.check()!

	console.print_header('dendrite start ok.')
}

pub fn (mut server Server) restart() ! {
	server.stop()!
	server.start()!
}

pub fn (mut server Server) stop() ! {
	print_backtrace()
	console.print_header('stop dendrite: ${server.name}')
	mut process := server.process or { return }
	return process.stop()
}

// check health, return true if ok
pub fn (mut server Server) check() ! {
	mut p := server.process or { return error("can't find process for server.") }
	p.check()!
	// TODO: need to do some other checks to dendrite e.g. rest calls
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

@[params]
pub struct UserAddArgs {
pub mut:
	name   string @[required]
	passwd string @[required]
	admin  bool
}

// remove all data
pub fn (mut server Server) user_add(args UserAddArgs) ! {
	mut admin := ''
	if args.admin {
		admin = '-admin'
	}
	cmd := '
		cd ${server.path_config.path}	
		dendrite-create-account --config dendrite.yaml -username ${args.name} -password ${args.passwd} ${admin} -url http://localhost:8008
		'
	console.print_debug(cmd)
	job := osal.exec(cmd: cmd)!
}
