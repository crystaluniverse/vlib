#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.core.base

pub struct MyClient[T] {
	base.BaseConfig[T]
}

@[params]
pub struct MyConfig {
pub mut:
	// the config items which are important to remember
	keyname string
	keyid   string
	appkey  string @[secret]
}

pub fn new(instance string, cfg MyConfig) !MyClient[MyConfig] {
	mut self := MyClient[MyConfig]{
		type_name: 'myclient'
	}
	self.init(instance: instance, action: .new)!
	self.config_set(cfg)!
	return self
}

pub fn get(instance string) !MyClient[MyConfig] {
	mut self := MyClient[MyConfig]{
		type_name: 'myclient'
	}
	self.init(instance: instance, action: .get)!
	return self
}

pub fn delete(instance string) ! {
	mut self := MyClient[MyConfig]{
		type_name: 'myclient'
	}
	self.init(instance: instance, action: .delete)!
}

// EXAMPLE USAGE

mut cl := new('testinstance', keyname: 'somekey', appkey: 'will be secret')!
myconfig := cl.config_get()!

// it should show how the fields are normal, but at back there was encryption/decryption of the field marked secret
println(myconfig)

config_content := $tmpl('aconfigfile.txt')

mut myconfigfile := pathlib.get_file(path: '/tmp/myconfigfile.txt', create: false)!
myconfigfile.write(config_content)!
