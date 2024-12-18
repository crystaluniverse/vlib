module taskletmanager

import freeflowuniverse.crystallib.core.pathlib

pub fn new(path string) !TaskletManager {
	mut p := pathlib.get(path)
	mut tm := TaskletManager{
		path: p
	}
	tm.scan()!
	return tm
}

pub fn generate(path string) !TaskletManager {
	mut tm := new(path)!
	tm.generate_code()!
	return tm
}
