module caddy

// import os
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.core.pathlib

pub struct Site {
pub mut:
	name        string
	domains     []Domain
	backends    []Backend
	paths       []pathlib.Path
	caddy       &Caddy @[skip; str: skip]
	description string
	status      SiteStatus
}

pub enum SiteStatus {
	unknown
	running // not used for now
	failed
}

@[params]
pub struct SiteNewArgs {
pub mut:
	name        string @[required]
	domains     []Domain
	backends    []Backend
	paths       []string // for serving local directory
	description string
}

//```
// name    string @[required]
// domains []Domain
// description string
//```
pub fn (mut caddy Caddy) site_add(args_ SiteNewArgs) !Site {
	mut args := args_

	mut p := Site{
		name:        args.name
		description: args.description
		caddy:       &caddy
		domains:     args.domains
		backends:    args.backends
	}

	return p
}
