#!/usr/bin/env -S v -cg -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.virt.hetzner
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.base
import freeflowuniverse.crystallib.builder
import time
import os

console.print_header('Hetzner login.')

// Check for required environment variables
user := os.getenv('HETZNER_USER')
if user == '' {
	eprintln('Error: HETZNER_USER environment variable is not set')
	eprintln('Please set it using: export HETZNER_USER=your-username')
	exit(1)
}

password := os.getenv('HETZNER_PASSWD')
if password == '' {
	eprintln('Error: HETZNER_PASSWD environment variable is not set')
	eprintln('Please set it using: export HETZNER_PASSWD=your-password')
	exit(1)
}

// Configure Hetzner using heroscript
heroscript := "
!!hetzner.configure
    name:'test'
    url:'https://robot-ws.your-server.de'
    user:'${user}'
    password:'${password}'
    whitelist:''
" // Play the heroscript to configure Hetzner (only needed once)

hetzner.play(heroscript: heroscript)!

// Get the Hetzner client instance
mut cl := hetzner.get(name: 'test')!

// EXAMPLE TO SHOW HOW TO REMOVE THE CACHE
// mut httpconnection:=cl.connection()!
// httpconnection.cache_drop()!

// keys:=cl.keys_get()!
// println(keys)

// for i in 0 .. 5 {
// 	println('test cache, first time slow then fast')
// 	cl.servers_list()!
// }

// servers:=cl.servers_list()!
// println(servers)

// mut serverinfo := cl.server_info_get(name: 'kristof2')!

// println(serverinfo)

// cl.server_reset(name:"kristof2",wait:true)!

// get the server in rescue mode, if its already in rescue then will not reboot, but just go there
// hero_install will make sure we have hero in the rescue server
mut n := cl.server_rescue_node(
	name:         'kristof2'
	wait:         true
	sshkey_name:  'kristof@incubaid.com'
	hero_install: true
)!
