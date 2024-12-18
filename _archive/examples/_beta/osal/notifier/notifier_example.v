module main

import freeflowuniverse.crystallib.osal.notifier

fn do() ! {
	mut n := notifier.new()!
}

fn main() {
	do() or { panic(err) }
}
