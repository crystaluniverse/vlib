module conduit

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.osal.zinit
import freeflowuniverse.crystallib.core.base
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.installers.db.postgresql
import freeflowuniverse.crystallib.installers.fediverse.conduit as conduit_installer
import json
import rand
import os
import time
import freeflowuniverse.crystallib.ui.console

pub struct Server[T] {
	base.BaseConfig[T]
pub mut:
	name        string
	path_config pathlib.Path
}

@[params]
pub struct Config {
pub mut:
	name                       string = 'default'
	reset                      bool
	path                       string = '/data/conduit'
	password                   string
	postgresql_name            string = 'default'
	domain                     string
	registration_shared_secret string
	recaptcha_public_key       string
	recaptcha_private_key      string
	recaptcha_bypass_secret    string
	path_config                pathlib.Path
	version                    string
}

// get the conduit server
//```js
// name        string = 'default'
// path        string = '/data/conduit'
// passwd      string
//```
pub fn get(instance string) !Server[Config] {
	console.print_header('get conduit server ${instance}')

	mut server := Server[Config]{}
	server.init('conduit_${instance}', instance, .get)!

	cfg := server.config()!
	conduit_installer.install(
		reset: cfg.reset
	)!

	return server
}

pub fn configure(instance string, config_ Config) !Server[Config] {
	mut config := config_
	if config.password == '' {
		config.password = rand.string(12)
	}

	conduit_installer.install(
		reset:   config.reset
		version: config.version
	)!

	mut server := Server[Config]{
		name:        config.name
		path_config: pathlib.get_dir(path: '${config.path}/cfg', create: true)!
	}

	server.init('caddy', instance, .set, config)!
	return server
}
