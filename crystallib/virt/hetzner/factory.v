module hetzner

import encoding.base64
import freeflowuniverse.crystallib.core.base
import freeflowuniverse.crystallib.core.playbook
import freeflowuniverse.crystallib.ui as gui
import freeflowuniverse.crystallib.ui.console

pub struct HetznerClient[T] {
	base.BaseConfig[T]
pub mut:
	auth string
}

@[params]
pub struct Config {
pub mut:
	login       string
	passwd      string @[secret]
	description string
	baseurl     string = 'https://robot-ws.your-server.de'
	whitelist   string // comma separated list of servers we whitelist to work on
}

pub fn get(instance string, cfg Config) !HetznerClient[Config] {
	mut self := HetznerClient[Config]{}

	if cfg.login.len > 0 {
		// first the type of the instance, then name of instance, then action
		self.init('hetznerclient', instance, .set, cfg)!
	} else {
		self.init('hetznerclient', instance, .get)!
	}

	mut cfg2 := self.config()!

	challenge := cfg2.login + ':' + cfg2.passwd
	self.auth = base64.encode(challenge.bytes())

	sl := self.servers_list()!
	console.print_debug(sl.str())

	return self
}

// get a new hetzner client, will create if it doesn't exist or ask for new configuration
pub fn configure(instance string) ! {
	mut cfg := Config{}
	mut ui := gui.new()!
	cfg.login = ui.ask_question(
		question: '\nPlease specify your login for your hetzner environment (instance:${instance}).'
	)!
	cfg.passwd = ui.ask_question(
		question: '\nPlease specify your passwd for your hetzner environment (instance:${instance}).'
	)!

	get(instance, cfg)!
}

// run heroscript starting from path, text or giturl
//```
// !!hetznerclient.define
//     name:'default'
//     description:'ThreeFold Read Write Repo 1
//     baseurl:'https://robot-ws.your-server.de'
//     login:'...'
//     passwd:'...'
//	   whitelist:'' //comma separated list of servers we whitelist to work on
//```	
pub fn heroplay(mut plbook playbook.PlayBook) ! {
	for mut action in plbook.find(filter: 'hetznerclient.define')! {
		mut p := action.params
		instance := p.get_default('instance', 'default')!
		// cfg.keyname = p.get('keyname')!
		mut cl := get(instance,
			login:       p.get('login')!
			passwd:      p.get('passwd')!
			description: p.get_default('description', '')!
			baseurl:     p.get_default('baseurl', '')!
		)!
		cl.config_save()!
	}
}
