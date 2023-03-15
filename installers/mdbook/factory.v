module mdbook

import freeflowuniverse.crystallib.builder

enum State {
	ok
	error
	reset
}

struct Installer {
	node  &builder.Node
	state State
}

pub fn get(mut node builder.Node) !Installer {
	mut i := Installer{
		node: &node
	}
	return i
}

pub fn get_install(mut node builder.Node) !Installer {
	mut i := Installer{
		node: &node
	}
	i.install()!
	return i
}

pub fn install() !Installer {
	mut builder_ := builder.new()
	mut node := builder_.node_local()!
	mut i := get(mut node)!
	i.install()!
	return i
}
