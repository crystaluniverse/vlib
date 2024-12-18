#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.threefold.tfrobot
import freeflowuniverse.crystallib.ui.console

console.print_header("Get VM's.")

for vm in tfrobot.vms_get('holotest2')! {
	console.print_debug(vm.str())
	mut node := vm.node()!
	r := node.exec(cmd: 'ls /')!
	println(r)
}
