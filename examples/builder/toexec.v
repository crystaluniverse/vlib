module main

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.installers.base

fn do() ! {
	base.uninstall_brew()!
	// println("something")
	// if osal.is_osx() {
	// 	println('IS OSX')
	// }

	// mut job2 := osal.exec(cmd: 'ls /')!
	// println(job2)
}

fn main() {
	do() or { panic(err) }
}
