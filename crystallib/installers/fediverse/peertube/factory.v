module peertube

// import freeflowuniverse.crystallib.osal
// import freeflowuniverse.crystallib.core.pathlib
// import freeflowuniverse.crystallib.develop.gittools
// import freeflowuniverse.crystallib.clients.mail
import freeflowuniverse.crystallib.core.texttools
import os

pub struct Peertube {
pub mut:
	name   string
	config Config
}

pub fn new(args_ Config) !Peertube {
	mut args := args_
	args.name = texttools.name_fix(args.name)

	configure_init(args.reset, mut args)!

	mut o := Peertube{
		name:   args.name
		config: args
	}

	return o
}

pub fn (mut self Peertube) configure(mut args Config) ! {
	// reset the values on the disk
	configure_init(true, mut args)!
}

fn checkplatform() ! {
	myplatform := osal.platform()
	if !(myplatform == .ubuntu || myplatform == .arch) {
		return error('platform not supported')
	}
}
