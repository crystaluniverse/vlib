module syncthing

import freeflowuniverse.crystallib.docker

pub struct App {
pub:
	name string
pub mut:
	instance string
	docker   docker.DockerEngine
	last_gid int
}

@[params]
pub struct AppArgs {
pub mut:
	instance        string = 'default'
	reset           bool
	deploy          bool = true
	sshkeys_allowed []string // ssh keys which will be inserted when a docker gets deployed (is not implemented yet)
	localonly       bool     // do you build for local utilization only
	prefix          string   // e.g. despiegk/ or myimage registry-host:5000/despiegk/) is added to the name when pushing	
}

pub fn new(args_ AppArgs) !App {
	mut args := args_
	if args.instance.len < 4 {
		return error('Instance needs to be +4 chars')
	}
	mut engine := docker.new(
		sshkeys_allowed: args.sshkeys_allowed
		localonly:       args.localonly
		prefix:          args.prefix
	)!

	mut a := App{
		name:   name
		docker: engine
	}
	if args.deploy {
		a.deploy()!
	}
	return a
}
