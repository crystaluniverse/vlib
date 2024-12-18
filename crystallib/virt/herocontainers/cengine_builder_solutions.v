module herocontainers

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.installers.virt.pacman
import os

@[params]
pub struct GetArgs {
	reset bool
}

// builder machine based on arch and install vlang
pub fn (mut e CEngine) builder_base(args GetArgs) !Builder {
	name := 'base'
	if !args.reset && e.builder_exists(name)! {
		return e.builder_get(name)!
	}
	console.print_header('buildah base build')

	// mut installer:= pacman.get()!
	// installer.install()!

	mut builder := e.builder_new(name: name, from: 'scratch', delete: true)!
	mount_path := builder.mount_to_path()!
	osal.exec(
		cmd: 'pacstrap -D -c ${mount_path} base screen bash coreutils curl mc unzip sudo which openssh'
	)!
	// builder.set_entrypoint('redis-server')!
	builder.commit('localhost/${name}')!
	return builder
}

// builder machine based on arch and install vlang
pub fn (mut e CEngine) builder_go_rust(args GetArgs) !Builder {
	console.print_header('buildah builder go rust')
	name := 'builder_go_rust'
	e.builder_base(reset: false)!
	if !args.reset && e.builder_exists(name)! {
		return e.builder_get(name)!
	}
	mut builder := e.builder_new(name: name, from: 'localhost/base', delete: true)!
	builder.hero_execute_cmd('installers -n golang,rust')!
	// builder.clean()!
	builder.commit('localhost/${name}')!
	e.load()!
	return builder
}

pub fn (mut e CEngine) builder_js(args GetArgs) !Builder {
	console.print_header('buildah builder js')
	name := 'builder_js'
	e.builder_base(reset: false)!
	if !args.reset && e.builder_exists(name)! {
		return e.builder_get(name)!
	}
	mut builder := e.builder_new(name: name, from: 'localhost/base', delete: true)!
	builder.hero_execute_cmd('installers -n nodejs')!
	// builder.clean()!
	builder.commit('localhost/${name}')!
	e.load()!
	return builder
}

pub fn (mut e CEngine) builder_js_python(args GetArgs) !Builder {
	console.print_header('buildah builder js python')
	name := 'builder_js_python'
	e.builder_js(reset: false)!
	if !args.reset && e.builder_exists(name)! {
		return e.builder_get(name)!
	}
	mut builder := e.builder_new(name: name, from: 'localhost/builder_js', delete: true)!
	builder.hero_execute_cmd('installers -n python')!
	// builder.clean()!
	builder.commit('localhost/${name}')!
	e.load()!
	return builder
}

pub fn (mut e CEngine) builder_crystal(args GetArgs) !Builder {
	console.print_header('buildah builder crystal dev')
	name := 'builder_crystal'
	e.builder_js_python(reset: false)!
	if !args.reset && e.builder_exists(name)! {
		return e.builder_get(name)!
	}
	mut builder := e.builder_new(name: name, from: 'localhost/builder_js_python', delete: true)!
	builder.hero_execute_cmd('installers -n crystal')!
	// builder.clean()!
	builder.commit('localhost/${name}')!
	e.load()!
	return builder
}

pub fn (mut e CEngine) builder_herodev(args GetArgs) !Builder {
	console.print_header('buildah builder hero dev')
	name := 'builder_herodev'
	e.builder_js_python(reset: false)!
	if !args.reset && e.builder_exists(name)! {
		return e.builder_get(name)!
	}
	mut builder := e.builder_new(name: name, from: 'localhost/builder_crystal', delete: true)!
	builder.hero_execute_cmd('installers -n herodev')!
	// builder.clean()!
	builder.commit('localhost/${name}')!
	e.load()!
	return builder
}

pub fn (mut e CEngine) builder_heroweb(args GetArgs) !Builder {
	console.print_header('buildah builder hero web')
	name := 'builder_heroweb'
	e.builder_go_rust(reset: false)!
	e.builder_crystal(reset: false)!
	if !args.reset && e.builder_exists(name)! {
		return e.builder_get(name)!
	}
	mut builder0 := e.builder_new(
		name:   'builder_heroweb_temp'
		from:   'localhost/builder_go_rust'
		delete: true
	)!
	builder0.hero_execute_cmd('installers -n heroweb')!
	// builder0.hero_execute_cmd("installers -n heroweb")!
	mpath := builder0.mount_to_path()!

	// copy the built binary to host
	osal.exec(
		cmd: '
		mkdir -p  ${os.home_dir()}/hero/var/bin
		cp ${mpath}/usr/local/bin/* ${os.home_dir()}/hero/var/bin/
	'
	)!

	builder0.delete()!
	mut builder2 := e.builder_new(name: name, from: 'localhost/builder_crystal', delete: true)!
	builder2.copy('${os.home_dir()}/hero/var/bin/', '/usr/local/bin/')!
	builder2.commit('localhost/${name}')!
	e.load()!
	return builder2
}
