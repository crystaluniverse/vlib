module main

import freeflowuniverse.crystallib.baobab.hero

fn do() ! {
	mut h := hero.new(
		url: 'https://github.com/threefoldtech/vbuilders/tree/development/3builders/examples/1'
	)!
	println(h)
}

fn main() {
	do() or { panic(err) }
}
