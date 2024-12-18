#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.base
import freeflowuniverse.crystallib.core.playcmds
import os

console.print_header('Threefold website example with zola.')

// get path local to the current script
path_my_actions := '${os.dir(@FILE)}'

mut session := play.session_new(
	// coderoot:'/tmp/code'
	interactive:   true
	playbook_path: path_my_actions
	run:           true // means we execute immediatelly the core hero actions
)!

playcmds.run(mut session)!
