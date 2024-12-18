module daguserver

import freeflowuniverse.crystallib.data.paramsparser

pub const version = '1.14.3'
const singleton = true
const default = true
const heroscript_default = "

!!daguserver.configure
    homedir: '{HOME}/hero/var/dagu'
    configpath: '{HOME}/.config/dagu/admin.yaml'
    username: 'admin'
    password: 'secretpassword'
    secret: ''
    title: 'My Hero DAG'
    host: 'localhost'
    port: 8888

// !!daguserver.start
// !!daguserver.stop
// !!daguserver.restart
// !!daguserver.delete
// !!daguserver.check

"

pub struct DaguServer {
pub mut:
	name       string = 'default'
	homedir    string
	configpath string
	username   string
	password   string @[secret]
	secret     string @[secret]
	title      string
	host       string
	port       int
}

fn cfg_play(p paramsparser.Params) ! {
	mut mycfg := DaguServer{
		homedir:    p.get_default('homedir', '{HOME}/hero/var/dagu')!
		configpath: p.get_default('configpath', '{HOME}/hero/var/dagu/admin.yaml')!
		username:   p.get_default('username', 'admin')!
		password:   p.get_default('password', '')!
		secret:     p.get_default('secret', '')!
		title:      p.get_default('title', 'HERO DAG')!
		host:       p.get_default('host', 'localhost')!
		port:       p.get_int_default('port', 8888)!
	}

	if mycfg.password == '' && mycfg.secret == '' {
		return error('password or secret needs to be filled in for dagu')
	}

	set(mycfg)!
}
