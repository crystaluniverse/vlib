module caddy

import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.sysadmin.startupmanager
import freeflowuniverse.crystallib.servers.caddy.security
import os

// Restart the Caddy
pub fn (mut self Caddy[Config]) restart() ! {
	self.stop()!
	self.start()!
}

// Restart the Caddy
pub fn (mut self Caddy[Config]) reload() ! {
	mut cfg := self.config()!
	cfg.file.export('${cfg.homedir}/Caddyfile.json')!
	osal.exec(cmd: 'caddy --config ${cfg.homedir}/Caddyfile.json reload')!
}

pub fn (mut self Caddy[Config]) start() ! {
	mut cfg := self.config()!
	console.print_header('caddy start')

	if cfg.homedir == '' {
		cfg.homedir = '/tmp/caddy'
	}

	// if !os.exists('${cfg.homedir}/Caddyfile.json') {
	// 	return error("didn't find caddyfile")
	// }

	cfg.file.export('${cfg.homedir}/Caddyfile.json')!

	cmd := 'caddy run --config ${cfg.homedir}/Caddyfile.json'

	mut sm := startupmanager.get()!

	sm.new(
		name:  'caddy'
		cmd:   cmd
		start: true
	)!
}

pub fn (mut self Caddy[Config]) stop() ! {
	console.print_header('caddy stop')
	mut sm := startupmanager.get()!
	sm.stop('caddy')!
}

pub fn (mut self Caddy[Config]) set_caddyfile(file CaddyFile) ! {
	mut cfg := self.config()!
	cfg.file = file
}
