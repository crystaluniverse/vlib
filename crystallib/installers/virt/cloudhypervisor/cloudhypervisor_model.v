module cloudhypervisor

import freeflowuniverse.crystallib.data.paramsparser
import os

pub const version0 = '41.0'
pub const version = '${version0}.0'
const singleton = true
const default = true

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED
pub struct CloudHypervisor {
pub mut:
	name string = 'default'
}

fn obj_init(obj_ CloudHypervisor) !CloudHypervisor {
	// never call get here, only thing we can do here is work on object itself
	mut obj := obj_
	return obj
}

// called before start if done
fn configure() ! {
	// mut installer := get()!
}
