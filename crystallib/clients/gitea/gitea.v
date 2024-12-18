module gitea

import freeflowuniverse.crystallib.clients.httpconnection
import freeflowuniverse.crystallib.core.base
import freeflowuniverse.crystallib.core.playbook

struct GiteaClient[T] {
	base.BaseConfig[T]
pub mut:
	connection &httpconnection.HTTPConnection
}

pub struct Config {
pub mut:
	url      string
	username string
	password string @[secret]
}

pub fn new(instance string, cfg Config) !GiteaClient[Config] {
	mut con := httpconnection.HTTPConnection{}
	mut self := GiteaClient[Config]{
		type_name:  'GiteaClient'
		connection: &con
	}
	self.init(instance: instance, action: .new)!
	self.config_set(cfg)!
	return self
}

// get instance of our client params
pub fn get(instance string) !GiteaClient[Config] {
	mut con := httpconnection.HTTPConnection{}
	mut self := GiteaClient[Config]{
		type_name:  'GiteaClient'
		connection: &con
	}

	self.init(instance: instance, action: .get)!
	return self
}

pub fn delete(instance string) ! {
	mut con := httpconnection.HTTPConnection{}
	mut self := GiteaClient[Config]{
		type_name:  'GiteaClient'
		connection: &con
	}

	self.init(instance: instance, action: .delete)!
}

//
pub fn heroplay(mut plbook playbook.PlayBook) ! {
	// make session for configuring from heroscript
	for mut action in plbook.find(filter: 'gitea_client.define')! {
		mut p := action.params
		instance := p.get_default('instance', 'default')!
		mut cl := get(instance)!
		mut cfg := cl.config_get()!
		cfg.url = p.get('url')!
		cfg.username = p.get('username')!
		cfg.password = p.get('password')!
		cl.config_save()!
	}
}
