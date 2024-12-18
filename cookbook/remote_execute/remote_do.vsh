#!/usr/bin/env -S v -n -w -enable-globals run

import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.builder
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.installers.net.mycelium
import freeflowuniverse.crystallib.installers.sysadmintools.daguserver

// the next statement makes the current script to be executed remotely
nodes := '65.21.132.119'
if builder.this_remote_exec(nodes: nodes, script: @FILE, sync_from_local: true)! {
	exit(0)
}

/////////////// Will be execute on remote

console.print_header('My remote test.')

println(osal.platform())

mycelium.install()!
dagu.install()!

// println(osal.proces_exists_byname("mycelium")!)
