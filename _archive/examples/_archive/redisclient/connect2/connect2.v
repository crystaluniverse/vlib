module main

import freeflowuniverse.crystallib.clients.redisclient

fn do() ! {
	mut r := redisclient.new(['localhost:7777', 'localhost:7778', 'localhost:7779'])!
	println(r)
	res := r.ping()!
	println(res)
}

fn main() {
	do() or { panic(err) }
}
