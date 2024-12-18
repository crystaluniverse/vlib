module namecom

import freeflowuniverse.crystallib.data.paramsparser
import os

pub const version = '0.0.0'
const singleton = false
const default = true

// TODO: THIS IS EXAMPLE CODE AND NEEDS TO BE CHANGED IN LINE TO STRUCT BELOW, IS STRUCTURED AS HEROSCRIPT
pub fn heroscript_default() !string {
	heroscript := "
    !!namecom.configure 
        name:'namecom'
        token:''
        "

	return heroscript
}

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED

pub struct NameComClient {
pub mut:
	name  string = 'default'
	token string
}

fn cfg_play(p paramsparser.Params) ! {
	// THIS IS EXAMPLE CODE AND NEEDS TO BE CHANGED IN LINE WITH struct above
	mut mycfg := NameComClient{
		name:  p.get_default('name', 'default')!
		token: p.get('token')!
	}
	set(mycfg)!
}

fn obj_init(obj_ NameComClient) !NameComClient {
	// never call get here, only thing we can do here is work on object itself
	mut obj := obj_
	return obj
}
