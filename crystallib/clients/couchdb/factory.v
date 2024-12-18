module couchdb

import freeflowuniverse.crystallib.core.base
import freeflowuniverse.crystallib.clients.httpconnection

// import freeflowuniverse.crystallib.ui.console

pub struct CouchDBClient[T] {
	base.BaseConfig[T]
pub mut:
	connection &httpconnection.HTTPConnection
	username   string
}

@[params]
pub struct Config {
pub mut:
	url      string
	username string
	password string @[secret]
}

pub fn get(instance string, cfg Config) !CouchDBClient[Config] {
	mut self := CouchDBClient[Config]{
		connection: &httpconnection.HTTPConnection{}
		username:   cfg.username
	}

	if cfg.username.len > 0 {
		// first the type of the instance, then name of instance, then action
		self.init('CouchDBclient', instance, .set, cfg)!
	} else {
		self.init('CouchDBclient', instance, .get)!
	}

	mut conn := httpconnection.new(
		name: 'CouchDB'
		url:  'http://${cfg.url}'
	)!

	// TODO: ...
	conn.basic_auth(cfg.username, cfg.password)
	// req.add_custom_header('x-disable-pagination', 'True') !

	self.connection = conn
	return self
}

// TODO: implement play... for configuraton
