module base

import json
import freeflowuniverse.crystallib.ui.console

@[heap]
pub struct Configurator[T] {
pub mut:
	// context     &Context @[skip; str: skip]
	instance    string
	description string
	configured  bool
	configtype  string // e.g. sshclient
}

@[params]
pub struct ConfiguratorArgs {
pub mut:
	// context  &Context // optional context for the configurator
	instance string @[required]
}

// name is e.g. mailclient (the type of configuration setting)
// instance is the instance of the config e.g. kds
// the context defines the context in which we operate, is optional will get the default one if not set
pub fn configurator_new[T](args ConfiguratorArgs) !Configurator[T] {
	return Configurator[T]{
		// context: args.context
		configtype: T.name.to_lower()
		instance:   args.instance
	}
}

fn (mut self Configurator[T]) config_key() string {
	return '${self.configtype}_config_${self.instance}'
}

// set the full configuration as one object to dbconfig
pub fn (mut self Configurator[T]) set(args T) ! {
	mut mycontext := context()!
	mut db := mycontext.db_config_get()!
	data := json.encode_pretty(args)
	db.set(key: self.config_key(), value: data)!
}

pub fn (mut self Configurator[T]) exists() !bool {
	mut mycontext := context()!
	mut db := mycontext.db_config_get()!
	return db.exists(key: self.config_key())
}

pub fn (mut self Configurator[T]) new() !T {
	return T{
		instance:    self.instance
		description: self.description
	}
}

pub fn (mut self Configurator[T]) get() !T {
	mut mycontext := context()!
	mut db := mycontext.db_config_get()!
	if !db.exists(key: self.config_key())! {
		return error("can't find configuration with name: ${self.config_key()} in context:'${mycontext.config.name}'")
	}
	data := db.get(key: self.config_key())!
	return json.decode(T, data)!
}

pub fn (mut self Configurator[T]) delete() ! {
	mut mycontext := context()!
	mut db := mycontext.db_config_get()!
	db.delete(key: self.config_key())!
}

pub fn (mut self Configurator[T]) getset(args T) !T {
	mut mycontext := context()!
	mut db := mycontext.db_config_get()!
	if db.exists(key: self.config_key())! {
		return self.get()!
	}
	self.set(args)!
	return self.get()!
}

@[params]
pub struct PrintArgs {
pub mut:
	name string
}

pub fn (mut self Configurator[T]) list() ![]string {
	panic('implement')
}

pub fn (mut self Configurator[T]) configprint(args PrintArgs) ! {
	mut mycontext := context()!
	mut db := mycontext.db_config_get()!
	if args.name.len > 0 {
		if db.exists(key: self.config_key())! {
			data := db.get(key: self.config_key())!
			c := json.decode(T, data)!
			console.print_debug('${c}')
			console.print_debug('')
		} else {
			return error("Can't find connection with name: ${args.name}")
		}
	} else {
		panic('implement')
		// for item in list()! {
		// 	// console.print_debug(" ==== $item")
		// 	configprint(name: item)!
		// }
	}
}

// init our class with the base session_args
// pub fn (mut self Configurator[T]) init(session_args_ SessionNewArgs) ! {
// 	self.session_=session_args.session or {
// 		session_new(session_args)!
// 	 }
// }
