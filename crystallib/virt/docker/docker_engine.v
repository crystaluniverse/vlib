module docker

import freeflowuniverse.crystallib.osal { cputype, exec, platform }
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.virt.utils
import freeflowuniverse.crystallib.ui.console
// import freeflowuniverse.crystallib.installers.swarm

// https://docs.docker.com/reference/

@[heap]
pub struct DockerEngine {
	name string
pub mut:
	sshkeys_allowed []string // all keys here have access over ssh into the machine, when ssh enabled
	images          []DockerImage
	containers      []DockerContainer
	buildpath       string
	localonly       bool
	cache           bool = true
	push            bool
	platform        []BuildPlatformType // used to build
	registries      []DockerRegistry    // one or more supported DockerRegistries
	prefix          string
}

pub enum BuildPlatformType {
	linux_arm64
	linux_amd64
}

// check docker has been installed & enabled on node
pub fn (mut e DockerEngine) init() ! {
	if e.buildpath == '' {
		e.buildpath = '/tmp/builder'
		exec(cmd: 'mkdir -p ${e.buildpath}', stdout: false)!
	}
	if e.platform == [] {
		if platform() == .ubuntu && cputype() == .intel {
			e.platform = [.linux_amd64]
		} else if platform() == .osx && cputype() == .arm {
			e.platform = [.linux_arm64]
		} else {
			return error('only implemented ubuntu on amd and osx on arm for now for docker engine.')
		}
	}
	e.load()!
}

// reload the state from system
pub fn (mut e DockerEngine) load() ! {
	e.images_load()!
	e.containers_load()!
}

// load all containers, they can be consulted in e.containers
// see obj: DockerContainer as result in e.containers
pub fn (mut e DockerEngine) containers_load() ! {
	e.containers = []DockerContainer{}
	mut ljob := exec(
		// we used || because sometimes the command has | in it and this will ruin all subsequent columns
		cmd:                "docker ps -a --no-trunc --format '{{.ID}}||{{.Names}}||{{.Image}}||{{.Command}}||{{.CreatedAt}}||{{.Ports}}||{{.State}}||{{.Size}}||{{.Mounts}}||{{.Networks}}||{{.Labels}}'"
		ignore_error_codes: [6]
		stdout:             false
	)!
	lines := ljob.output
	for line in lines {
		if line.trim_space() == '' {
			continue
		}
		fields := line.split('||').map(utils.clear_str)
		if fields.len < 11 {
			panic('docker ps needs to output 11 parts.\n${fields}')
		}
		id := fields[0]
		mut container := DockerContainer{
			engine: &e
			image:  e.image_get(id: fields[2])!
		}

		container.id = id
		container.name = texttools.name_fix(fields[1])
		container.command = fields[3]
		container.created = utils.parse_time(fields[4])!
		container.ports = utils.parse_ports(fields[5])!
		container.status = utils.parse_container_state(fields[6])!
		container.memsize = utils.parse_size_mb(fields[7])!
		container.mounts = utils.parse_mounts(fields[8])!
		container.networks = utils.parse_networks(fields[9])!
		container.labels = utils.parse_labels(fields[10])!
		container.ssh_enabled = utils.contains_ssh_port(container.ports)
		// console.print_debug(container)
		e.containers << container
	}
}

// EXISTS, GET

@[params]
pub struct ContainerGetArgs {
pub mut:
	name     string
	id       string
	image_id string
	// tag    string
	// digest string
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
		return 'Found more than 1 container with args:\n${err.args}'
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

// get containers from memory
// params:
//   name   string  (can also be a glob e.g. use *,? and [])
//   id     string
//   image_id string
pub fn (mut e DockerEngine) containers_get(args_ ContainerGetArgs) ![]&DockerContainer {
	mut args := args_
	args.name = texttools.name_fix(args.name)
	mut res := []&DockerContainer{}
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
pub fn (mut e DockerEngine) container_get(args_ ContainerGetArgs) !&DockerContainer {
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

pub fn (mut e DockerEngine) container_exists(args ContainerGetArgs) !bool {
	e.container_get(args) or {
		if err.code() == 1 {
			return false
		}
		return err
	}
	return true
}

pub fn (mut e DockerEngine) container_delete(args ContainerGetArgs) ! {
	mut c := e.container_get(args)!
	c.delete()!
	e.load()!
}

// remove one or more container
pub fn (mut e DockerEngine) containers_delete(args ContainerGetArgs) ! {
	mut cs := e.containers_get(args)!
	for mut c in cs {
		c.delete()!
	}
	e.load()!
}

// import a container into an image, run docker container with it
// image_repo examples ['myimage', 'myimage:latest']
// if DockerContainerCreateArgs contains a name, container will be created and restarted
pub fn (mut e DockerEngine) container_import(path string, mut args DockerContainerCreateArgs) !&DockerContainer {
	mut image := args.image_repo
	if args.image_tag != '' {
		image = image + ':${args.image_tag}'
	}

	exec(cmd: 'docker import  ${path} ${image}', stdout: false)!
	// make sure we start from loaded image
	return e.container_create(args)
}

// reset all images & containers, CAREFUL!
pub fn (mut e DockerEngine) reset_all() ! {
	for mut container in e.containers.clone() {
		container.delete()!
	}
	for mut image in e.images.clone() {
		image.delete(true)!
	}
	exec(cmd: 'docker image prune -a -f', stdout: false) or { panic(err) }
	exec(cmd: 'docker builder prune -a -f', stdout: false) or { panic(err) }
	osal.done_reset()!
	e.load()!
}

// Get free port
pub fn (mut e DockerEngine) get_free_port() ?int {
	mut used_ports := []int{}
	mut range := []int{}

	for c in e.containers {
		for p in c.forwarded_ports {
			used_ports << p.split(':')[0].int()
		}
	}

	for i in 20000 .. 40000 {
		if i !in used_ports {
			range << i
		}
	}
	// arrays.shuffle<int>(mut range, 0)
	if range.len == 0 {
		return none
	}
	return range[0]
}
