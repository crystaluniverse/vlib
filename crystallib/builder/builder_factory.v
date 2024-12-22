module builder

import freeflowuniverse.crystallib.core.base

@[heap]
pub struct BuilderFactory {
}

pub fn new() !BuilderFactory {
	_ := base.context()!
	mut bf := BuilderFactory{}
	return bf
}

@[params]
pub struct NodeLocalArgs {
pub:
	reload bool
}

pub fn node_local(args NodeLocalArgs) !&Node {
	mut bldr := new()!
	return bldr.node_new(name: 'localhost', reload: args.reload)
}
