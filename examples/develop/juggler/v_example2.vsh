#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.sysadmin.startupmanager
import os

mut sm := startupmanager.get()!
sm.start(
	name:    'juggler'
	cmd:     'hero juggler -secret planetfirst -u https://git.ourworld.tf/projectmycelium/itenv -reset true'
	env:     {
		'HOME': os.home_dir()
	}
	restart: true
) or { panic('failed to start sm ${err}') }

// TODO
// - automate caddy install/start
// - create server/caddy which only calls install & can set config file from path or url & restart (see dagu server)
// - get caddy config from the itenv through (simple driver)
// - caddy through startup manager, also for dagu
// - expose dagu UI over caddy & make sure we use secret
// - have heroscript starting from itenv to start a full env (with secret): 'hero juggler -i -s mysecret --dns juggler2.protocol.me '
// - use domain name use https://github.com/Incubaid/dns/blob/main/protocol.me.lua  over git ssh
