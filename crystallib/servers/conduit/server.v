module conduit

import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.sysadmin.startupmanager
import os

pub fn (mut server Server[Config]) start() ! {
	config := server.config()!
	console.print_header('start conduit: ${server.name}')

	t1 := $tmpl('templates/conduit.yaml').replace('??', '@')

	mut config_path := server.path_config.file_get_new('conduit.yaml')!
	config_path.write(t1)!

	kpath1 := '${server.path_config.path}/matrix_key.pem'
	if !os.exists(kpath1) {
		osal.exec(cmd: 'conduit-generate-keys --private-key ${kpath1}')!
	}

	keyspath := '/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${config.domain}'
	if !os.exists(keyspath) {
		return error('cannot find letsencrypt keys for caddy in: ${keyspath}')
	}

	os.cp('${keyspath}/${config.domain}.crt', '${server.path_config.path}/server.crt')!
	os.cp('${keyspath}/${config.domain}.key', '${server.path_config.path}/server.key')!

	mut sm := startupmanager.get()!
	sm.start(
		name: server.process_name()
		cmd:  'cd ${server.path_config.path} \n conduit'
	)!

	server.check()!

	console.print_header('conduit start ok.')
	console.print_header('conduit start')
}

pub fn (mut server Server[Config]) stop() ! {
	console.print_header('conduit stop')
	mut sm := startupmanager.get()!
	sm.stop(server.process_name())!
}

pub fn (mut server Server[Config]) restart() ! {
	server.stop()!
	server.start()!
}

pub fn (mut server Server[Config]) status() !startupmanager.ProcessStatus {
	mut sm := startupmanager.get()!
	return sm.status(server.process_name()) or { return .unknown }
}

// check health, return true if ok
pub fn (mut server Server[Config]) check() ! {
	// TODO: need to do some other checks to conduit e.g. rest calls
}

// check health, return true if ok
pub fn (mut server Server[Config]) ok() bool {
	server.check() or { return false }
	return true
}

// remove all data
pub fn (mut server Server[Config]) destroy() ! {
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
pub fn (mut server Server[Config]) user_add(args UserAddArgs) ! {
	mut admin := ''
	if args.admin {
		admin = '-admin'
	}
	cmd := '
		cd ${server.path_config.path}	
		conduit-create-account --config conduit.yaml -username ${args.name} -password ${args.passwd} ${admin} -url http://localhost:8008
		'
	console.print_debug(cmd)
	job := osal.exec(cmd: cmd)!
}

fn (server Server[Config]) process_name() string {
	return 'conduit_${server.name}'
}
