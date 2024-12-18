#!/usr/bin/env -S v -n -w -enable-globals run

import freeflowuniverse.crystallib.installers.base
import freeflowuniverse.crystallib.builder
import freeflowuniverse.crystallib.osal
import os

mut server := ''
env := os.environ()
if 'SERVER' in env {
	server = env['SERVER']
}

if server == '' {
	println('specify server you want to debug on as e.g. export SERVER=65.21.132.119')
	exit(1)
}

mut b := builder.new()!
mut n := b.node_new(ipaddr: server)!

// osal.exec(cmd:"${os.home_dir()}/code/github/freeflowuniverse/crystallib/cli/hero/compile_debug.sh",stdout:true)!

n.upload(source: '/tmp/hero', dest: '/tmp/hero')!

println('execute installer')
n.exec(
	cmd:    '

	#with hero (will compile hero as well)
	curl https://raw.githubusercontent.com/freeflowuniverse/crystallib/development/scripts/build_hero.sh > /tmp/build_hero.sh
	bash /tmp/build_hero.sh
	'
	stdout: true
)!
