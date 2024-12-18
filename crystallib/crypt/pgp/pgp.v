module pgp

// import freeflowuniverse.crystallib.builder
import os

pub enum PGPFactoryStatus {
	init
	ok
	error
}

@[heap]
struct PGPFactory {
mut:
	path      string
	instances map[string]PGPInstance
}

// needed to get singleton
fn init2() PGPFactory {
	mut f := PGPFactory{}
	// untill we have pgp bindings to the vlang module, we prob need to use command line
	f.path = '...'
	f.cmd = '...'
	return f
}

// singleton creation
const factory = init2()

pub fn get() &PGPFactory {
	return &factory
}
