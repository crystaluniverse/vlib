module caddy

import freeflowuniverse.crystallib.data.paramsparser

pub const xcaddy_version = '0.4.2'
pub const caddy_version = '2.8.4'
const singleton = true
const default = true

const heroscript_default = "
!!caddy.configure
    path: ''
    domain: ''
    plugins: ''
"

// CaddyServer represents a Caddy server configuration.
pub struct CaddyServer {
pub mut:
	// name is the name of the Caddy server.
	name string = 'default'

	// path is the path to the server's root directory.
	path string = '/var/www'

	// domain is the default domain for the server.
	domain string // sort of default domain

	// plugins is a list of plugins to be used by the server.
	plugins []string
}

fn cfg_play(p paramsparser.Params) ! {
	mut mycfg := CaddyServer{
		path:    p.get_default('homedir', '{HOME}/hero/var/caddy')!
		domain:  p.get_default('configpath', '{HOME}/hero/var/caddy/admin.yaml')!
		plugins: p.get_list_default('plugins', []string{})!
	}

	if mycfg.path == '' && mycfg.domain == '' {
		return error('path or domain needs to be filled in for caddy')
	}

	set(mycfg)!
}
