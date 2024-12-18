#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.base
import freeflowuniverse.crystallib.core.playcmds
import os

const url = 'https://github.com/freeflowuniverse/crystallib/tree/development/examples/webtools/zola/zola_heroscript'

console.print_header('Some test with zola.')

// get path local to the current script
path_my_actions := '${os.dir(@FILE)}/zola_heroscript'

mut session := play.session_new(
	// coderoot:'/tmp/code'
	interactive:  true
	playbook_url: url
	run:          true // means we execute immediatelly the core hero actions
)!

playcmds.run(mut session)!
