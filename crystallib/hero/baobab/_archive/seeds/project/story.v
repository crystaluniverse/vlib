module project

import freeflowuniverse.crystallib.baobab.base

pub struct Story {
pub mut:
	id   string
	name string @[required]
	tag  string @[index]
}
