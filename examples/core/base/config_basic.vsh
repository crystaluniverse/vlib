#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

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

// EXAMPLE USAGE

mut cl := new('testinstance', keyname: 'somekey', appkey: 'will be secret')!
println(cl.config_get()!)

// now get the client, will give error if it doesn't exist
mut cl2 := get('testinstance')!
println(cl2.config_get()!)

delete('testinstance')!
