module main

import os
import time
import freeflowuniverse.crystallib.osal.initd

fn main() {
	do() or { panic(err) }
}

fn do() ! {
	mut id := initd.new()!
	println(id)

	mut p := id.new(
		cmd:         '/usr/local/bin/zinit init'
		name:        'zinit'
		description: 'a super easy to use startup manager.'
	)!
	p.start()!
	p.remove()!
}
