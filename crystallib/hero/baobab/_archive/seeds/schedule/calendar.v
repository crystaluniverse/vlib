module schedule

import freeflowuniverse.crystallib.baobab.base

pub struct Calendar {
	base.Base
pub mut:
	calendar_name string
	tag           string @[index]
}
