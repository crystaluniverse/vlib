module osinstaller

import os
import freeflowuniverse.crystallib.ui.console
// import json
// import maxux.vssh

struct ServerManager {
	root string
}

pub fn new() ServerManager {
	sm := ServerManager{}
	return sm
}

fn (s ServerManager) execute(command string) bool {
	// console.print_debug(command)

	r := os.execute(command)
	// console.print_debug(r)

	return true
}
