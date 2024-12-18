module caddy

import freeflowuniverse.crystallib.core.base
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.installers.web.caddy as caddyinstaller
import os
import time

fn test_configure() {
	instance := 'test_instance'
	cfg := Config{
		homedir: '/tmp/caddy'
		reset:   false
		file:    CaddyFile{}
	}

	// Ensure the Caddyfile does not exist initially
	os.rm('/tmp/caddy/Caddyfile') or {}

	mut caddy_instance := configure(instance, cfg) or {
		assert false, 'Failed to configure Caddy instance: ${err}'
		return
	}

	// Validate the Caddy instance
	cfg_ := caddy_instance.config()!
	assert cfg_.homedir == '/tmp/caddy', 'Expected home directory to be "/tmp/caddy"'
}

fn test_get() {
	instance := 'test_instance'
	mut cfg := Config{
		homedir: '/tmp/caddy'
		reset:   false
		file:    CaddyFile{}
	}

	mut caddy_instance := configure(instance, cfg) or {
		assert false, 'Failed to configure Caddy instance: ${err}'
		return
	}

	caddy_instance = get(instance) or {
		assert false, 'Failed to get Caddy instance: ${err}'
		return
	}

	cfg = caddy_instance.config()!
	assert cfg.homedir == '/tmp/caddy', 'Expected base name to be "caddy"'

	caddy_instance = get('') or {
		assert false, 'Failed to get Caddy instance: ${err}'
		return
	}

	cfg = caddy_instance.config()!
	assert cfg.homedir == '/etc/caddy', 'Expected base name to be "caddy"'
}
