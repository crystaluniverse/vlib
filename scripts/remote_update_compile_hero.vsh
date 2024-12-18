#!/usr/bin/env -S v -n -w -enable-globals run

import freeflowuniverse.crystallib.installers.base
import freeflowuniverse.crystallib.builder
import os

const mydir = os.dir(@FILE)

server := os.environ()['SERVER'] or { '' }
if server == '' {
	println('specify server you want to debug on as e.g. export SERVER=65.21.132.119')
	exit(1)
}

mut b := builder.new()!
mut n := b.node_new(ipaddr: server)!

// PARAMS FOR CRYSTAL UPDATE
// 	sync_from_local bool //will sync local crystal lib to the remote, then cannot use git
// 	sync_full bool //sync the full crystallib repo
// 	git_reset bool //will get the code from github at remote and reset changes
// 	git_pull bool //will pull the code but not reset, will give error if it can't reset	

// n.crystal_update(sync_from_local:true)!
n.crystal_update(git_reset: true, branch: 'development')!
n.hero_compile()!
