module herocontainers

import freeflowuniverse.crystallib.osal { exec }
// import freeflowuniverse.crystallib.data.ipaddress { IPAddress }
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.virt.utils
// import freeflowuniverse.crystallib.ui.console

// load all containers, they can be consulted in e.containers
// see obj: Container as result in e.containers
fn (mut e CEngine) containers_load() ! {
	e.containers = []Container{}
	mut ljob := exec(
		// we used || because sometimes the command has | in it and this will ruin all subsequent columns
		cmd:                "podman container list -a --no-trunc --size --format '{{.ID}}||{{.Names}}||{{.ImageID}}||{{.Command}}||{{.CreatedAt}}||{{.Ports}}||{{.State}}||{{.Size}}||{{.Mounts}}||{{.Networks}}||{{.Labels}}'"
		ignore_error_codes: [6]
		stdout:             false
	)!
	lines := ljob.output.split_into_lines()
	for line in lines {
		if line.trim_space() == '' {
			continue
		}
		fields := line.split('||').map(utils.clear_str)
		if fields.len < 11 {
			panic('podman ps needs to output 11 parts.\n${fields}')
		}
		id := fields[0]
		// if image doesn't have id skip this container, maybe ran from filesystme
		if fields[2] == '' {
			continue
		}
		mut image := e.image_get(id_full: fields[2])!
		mut container := Container{
			engine: &e
			image:  &image
		}
		container.id = id
		container.name = texttools.name_fix(fields[1])
		container.command = fields[3]
		container.created = utils.parse_time(fields[4])!
		container.ports = utils.parse_ports(fields[5])!
		container.status = utils.parse_container_state(fields[6])!
		container.memsize = utils.parse_size_mb(fields[7])!
		container.mounts = utils.parse_mounts(fields[8])!
		container.mounts = []
		container.networks = utils.parse_networks(fields[9])!
		container.labels = utils.parse_labels(fields[10])!
		container.ssh_enabled = utils.contains_ssh_port(container.ports)
		e.containers << container
	}
}

@[params]
pub struct ContainerGetArgs {
pub mut:
	name     string
	id       string
	image_id string
	// tag    string
	// digest string
}

// get containers from memory
// params:
//   name   string  (can also be a glob e.g. use *,? and [])
//   id     string
//   image_id string
pub fn (mut e CEngine) containers_get(args_ ContainerGetArgs) ![]&Container {
	mut args := args_
	args.name = texttools.name_fix(args.name)
	mut res := []&Container{}
	for _, c in e.containers {
		if args.name.contains('*') || args.name.contains('?') || args.name.contains('[') {
			if c.name.match_glob(args.name) {
				res << &c
				continue
			}
		} else {
			if c.name == args.name || c.id == args.id {
				res << &c
				continue
			}
		}
		if args.image_id.len > 0 && c.image.id == args.image_id {
			res << &c
		}
	}
	if res.len == 0 {
		return ContainerGetError{
			args:     args
			notfound: true
		}
	}
	return res
}

// get container from memory, can use match_glob see https://modules.vlang.io/index.html#string.match_glob
pub fn (mut e CEngine) container_get(args_ ContainerGetArgs) !&Container {
	mut args := args_
	args.name = texttools.name_fix(args.name)
	mut res := e.containers_get(args)!
	if res.len > 1 {
		return ContainerGetError{
			args:     args
			notfound: true
		}
	}
	return res[0]
}

pub fn (mut e CEngine) container_exists(args ContainerGetArgs) !bool {
	e.container_get(args) or {
		if err.code() == 1 {
			return false
		}
		return err
	}
	return true
}

pub fn (mut e CEngine) container_delete(args ContainerGetArgs) ! {
	mut c := e.container_get(args)!
	c.delete()!
	e.load()!
}

// remove one or more container
pub fn (mut e CEngine) containers_delete(args ContainerGetArgs) ! {
	mut cs := e.containers_get(args)!
	for mut c in cs {
		c.delete()!
	}
	e.load()!
}

pub struct ContainerGetError {
	Error
pub:
	args     ContainerGetArgs
	notfound bool
	toomany  bool
}

pub fn (err ContainerGetError) msg() string {
	if err.notfound {
		return 'Could not find image with args:\n${err.args}'
	}
	if err.toomany {
		return 'can not get container, Found more than 1 container with args:\n${err.args}'
	}
	panic('unknown error for ContainerGetError')
}

pub fn (err ContainerGetError) code() int {
	if err.notfound {
		return 1
	}
	if err.toomany {
		return 2
	}
	panic('unknown error for ContainerGetError')
}
