module juggler

import os
import freeflowuniverse.crystallib.servers.caddy
import freeflowuniverse.crystallib.develop.gittools
import freeflowuniverse.crystallib.baobab.actor
import freeflowuniverse.crystallib.core.pathlib

pub fn get(j Juggler) !&Juggler {
	// get so is also installed
	mut c := caddy.get(j.name)!
	return &Juggler{
		...j
	}
}

pub struct Config {
pub mut:
	name     string
	url      string
	reset    bool
	pull     bool
	port     int
	host     string
	coderoot string
	username string
	password string
	secret   string
}

pub fn configure(cfg Config) !&Juggler {
	config_path := code_get(cfg)!
	mut config_dir := pathlib.get_dir(path: config_path)!

	config_script := pathlib.get_file(path: '${config_dir.path}/config.hero')!

	// start caddyserver
	mut c := caddy.configure('juggler')!

	mut j := Juggler{
		Actor:       actor.new(
			name:   'admin'
			secret: cfg.password
		)!
		name:        cfg.name
		url:         cfg.url
		port:        cfg.port
		host:        cfg.host
		username:    cfg.username
		password:    cfg.password
		secret:      cfg.secret
		config_path: config_path
	}

	if cfg.reset {
		j.osis.reset_all()!
	}

	j.load(config_path)!
	return &j
}
