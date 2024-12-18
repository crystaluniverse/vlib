module taskletmanager

import freeflowuniverse.crystallib.core.pathlib

pub struct TaskletManager {
pub mut:
	path    pathlib.Path
	domains map[string]&Domain
}

pub struct Domain {
pub mut:
	name   string
	path   pathlib.Path
	actors map[string]&Actor
}

pub struct Actor {
pub mut:
	name    string
	path    pathlib.Path
	actions map[string][]&Action
}

pub struct Action {
pub mut:
	name     string
	namelong string // is the name with the instance inside, needed to be able to call the method
	instance string = 'default'
}
