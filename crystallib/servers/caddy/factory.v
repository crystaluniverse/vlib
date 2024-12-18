module caddy

import freeflowuniverse.crystallib.core.base
import freeflowuniverse.crystallib.core.pathlib
// import freeflowuniverse.crystallib.installers.web.caddy as caddyinstaller

// import freeflowuniverse.crystallib.ui.console

pub struct Caddy[T] {
	base.BaseConfig[T]
}

@[params]
pub struct Config {
pub mut:
	homedir string = '/etc/caddy'
	reset   bool
	file    CaddyFile
	plugins []string
}

pub fn get(instance string) !Caddy[Config] {
	mut self := Caddy[Config]{}
	self.init('caddy', instance, .get)!
	return self
}

// set the configuration, will make defaults for passwd & secret
pub fn configure(instance string, cfg_ Config) !Caddy[Config] {
	mut cfg := cfg_
	mut self := Caddy[Config]{}

	// caddyinstaller.install(
	// 	homedir: cfg.homedir
	// 	reset: cfg.reset
	// 	plugins: cfg.plugins
	// )!

	self.init('caddy', instance, .set, cfg)!

	return self
}
