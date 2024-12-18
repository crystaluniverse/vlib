#!/usr/bin/env -S v -n -w -enable-globals run

import freeflowuniverse.crystallib.installers.base
import freeflowuniverse.crystallib.builder
import os

mypath := base.bash_installers_package()!
println(' - packaged succesfully')

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

n.upload(source: '${mypath}/installer.sh', dest: '/tmp/installer.sh')!
println('execute installer')
n.exec(cmd: 'bash /tmp/installer.sh', stdout: true)!
