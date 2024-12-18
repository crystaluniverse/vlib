module vstor

import freeflowuniverse.crystallib.core.pathlib
import time

// TODO: define what is good way to specify a location, what do we have in TFChain
pub struct Location {
pub mut:
	farmid      string // as in TFChain
	name        string
	description string
}

pub fn (mut vstor VSTOR) location_new(args Location) !Location {
	// maintain all properties as defined before only change the ZDB's
	mut location := Location{
		address:     args.address
		name:        args.name
		description: args.description
	}
	return location
}
