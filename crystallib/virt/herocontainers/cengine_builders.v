module herocontainers

import freeflowuniverse.crystallib.osal
// import freeflowuniverse.crystallib.ui.console
import json

fn (mut e CEngine) builders_load() ! {
	cmd := 'buildah containers --json'
	out := osal.execute_silent(cmd)!
	mut r := json.decode([]Builder, out) or { return error('Failed to decode JSON: ${err}') }
	for mut item in r {
		item.engine = &e
	}
	e.builders = r
}

@[params]
pub struct BuilderNewArgs {
pub mut:
	name string = 'default'
	from string = 'docker.io/archlinux:latest'
	// arch_scratch bool // means start from scratch with arch linux
	delete bool = true
}

pub fn (mut e CEngine) builder_new(args_ BuilderNewArgs) !Builder {
	mut args := args_
	if args.delete {
		e.builder_delete(args.name)!
	}
	osal.exec(cmd: 'buildah --name ${args.name} from ${args.from}')!
	e.builders_load()!
	return e.builder_get(args.name)
}

// get buildah containers
pub fn (mut e CEngine) builders_get() ![]Builder {
	if e.builders.len == 0 {
		e.builders_load()!
	}
	return e.builders
}

pub fn (mut e CEngine) builder_exists(name string) !bool {
	r := e.builders_get()!
	res := r.filter(it.containername == name)
	if res.len == 1 {
		return true
	}
	if res.len > 1 {
		panic('bug')
	}
	return false
}

pub fn (mut e CEngine) builder_get(name string) !Builder {
	r := e.builders_get()!
	res := r.filter(it.containername == name)
	if res.len == 1 {
		return res[0]
	}
	if res.len > 1 {
		panic('bug')
	}
	return error('couldnt find builder with name ${name}')
}

pub fn (mut e CEngine) builders_delete_all() ! {
	osal.execute_stdout('buildah rm -a')!
	e.builders_load()!
}

pub fn (mut e CEngine) builder_delete(name string) ! {
	if e.builder_exists(name)! {
		osal.execute_stdout('buildah rm ${name}')!
		e.builders_load()!
	}
}

pub fn (mut e CEngine) builder_names() ![]string {
	r := e.builders_get()!
	return r.map(it.containername)
}
