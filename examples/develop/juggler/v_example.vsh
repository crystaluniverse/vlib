#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import os
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.develop.juggler
import veb

osal.load_env_file('${os.dir(@FILE)}/.env')!

mut j := juggler.configure(
	url:      'https://git.ourworld.tf/projectmycelium/itenv'
	username: os.getenv('JUGGLER_USERNAME')
	password: os.getenv('JUGGLER_PASSWORD')
	reset:    true
)!

spawn j.run(8000)
println(j.info())

for {}

// TODO
// - automate caddy install/start
// - create server/caddy which only calls install & can set config file from path or url & restart (see dagu server)
// - get caddy config from the itenv through (simple driver)
// - caddy through startup manager, also for dagu
// - expose dagu UI over caddy & make sure we use secret
// - have heroscript starting from itenv to start a full env (with secret): 'hero juggler -i -s mysecret --dns juggler2.protocol.me '
// - use domain name use https://github.com/Incubaid/dns/blob/main/protocol.me.lua  over git ssh
