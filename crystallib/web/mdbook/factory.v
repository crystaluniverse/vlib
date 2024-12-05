module mdbook

import freeflowuniverse.crystallib.core.base
import os
import crypto.md5

@[heap]
pub struct MDBooks[T] {
	base.BaseConfig[T]
}

@[params]
pub struct Config {
pub mut:
	path_build   string = '${os.home_dir()}/hero/var/mdbuild'
	path_publish string = '${os.home_dir()}/hero/www/info'
}

pub fn get(cfg_ Config) !MDBooks[Config] {
	mut c := base.context()!
	// lets get a unique name based on the used build and publishpaths
	mut cfg := cfg_
	cfg.path_build = cfg.path_build.replace('~', os.home_dir())
	cfg.path_publish = cfg.path_publish.replace('~', os.home_dir())
	mut name := md5.hexhash('${cfg.path_build}${cfg.path_publish}')
	mut myparams := c.params()!
	mut self := MDBooks[Config]{}
	if myparams.exists('mdbookname') {
		name = myparams.get('mdbookname')!
		self.init('mdbook', name, .get, cfg)!
	} else {
		self.init('mdbook', name, .set, cfg)!
		myparams.set('mdbookname', name)
	}
	return self
}
