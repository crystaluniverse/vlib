#!/usr/bin/env v -w -enable-globals run

import freeflowuniverse.crystallib.threefold.tfrobot
import freeflowuniverse.crystallib.ui.console

console.print_header("Get VM's.")


for vm in tfrobot.vms_get('holotest')!{
	console.print_debug(vm.str())
	mut node:=vm.node()!
	node.exec(cmd:"ls /")!
}
