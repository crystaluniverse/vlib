module postgresql

import freeflowuniverse.crystallib.core.base
import freeflowuniverse.crystallib.core.playbook
import freeflowuniverse.crystallib.sysadmin.startupmanager
import freeflowuniverse.crystallib.osal.zinit
import freeflowuniverse.crystallib.ui.console
import time

__global (
	postgresql_global  map[string]&Postgresql
	postgresql_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name string
}

fn args_get(args_ ArgsGet) ArgsGet {
	mut args := args_
	if args.name == '' {
		args.name = postgresql_default
	}
	if args.name == '' {
		args.name = 'default'
	}
	return args
}

pub fn get(args_ ArgsGet) !&Postgresql {
	mut args := args_get(args_)
	if args.name !in postgresql_global {
		if args.name == 'default' {
			if !config_exists(args) {
				if default {
					config_save(args)!
				}
			}
			config_load(args)!
		}
	}
	return postgresql_global[args.name] or {
		println(postgresql_global)
		panic('could not get config for postgresql with name:${args.name}')
	}
}

fn config_exists(args_ ArgsGet) bool {
	mut args := args_get(args_)
	mut context := base.context() or { panic('bug') }
	return context.hero_config_exists('postgresql', args.name)
}

fn config_load(args_ ArgsGet) ! {
	mut args := args_get(args_)
	mut context := base.context()!
	mut heroscript := context.hero_config_get('postgresql', args.name)!
	play(heroscript: heroscript)!
}

fn config_save(args_ ArgsGet) ! {
	mut args := args_get(args_)
	mut context := base.context()!
	context.hero_config_set('postgresql', args.name, heroscript_default()!)!
}

fn set(o Postgresql) ! {
	mut o2 := obj_init(o)!
	postgresql_global[o.name] = &o2
	postgresql_default = o.name
}

@[params]
pub struct PlayArgs {
pub mut:
	heroscript string // if filled in then plbook will be made out of it
	plbook     ?playbook.PlayBook
	reset      bool
}

pub fn play(args_ PlayArgs) ! {
	mut args := args_

	if args.heroscript == '' {
		args.heroscript = heroscript_default()!
	}
	mut plbook := args.plbook or { playbook.new(text: args.heroscript)! }

	mut install_actions := plbook.find(filter: 'postgresql.configure')!
	if install_actions.len > 0 {
		for install_action in install_actions {
			mut p := install_action.params
			mycfg := cfg_play(p)!
			console.print_debug('install action postgresql.configure\n${mycfg}')
			set(mycfg)!
		}
	}

	mut other_actions := plbook.find(filter: 'postgresql.')!
	for other_action in other_actions {
		if other_action.name in ['destroy', 'install', 'build'] {
			mut p := other_action.params
			reset := p.get_default_false('reset')
			if other_action.name == 'destroy' || reset {
				console.print_debug('install action postgresql.destroy')
				destroy()!
			}
			if other_action.name == 'install' {
				console.print_debug('install action postgresql.install')
				install()!
			}
		}
		if other_action.name in ['start', 'stop', 'restart'] {
			mut p := other_action.params
			name := p.get('name')!
			mut postgresql_obj := get(name: name)!
			console.print_debug('action object:\n${postgresql_obj}')
			if other_action.name == 'start' {
				console.print_debug('install action postgresql.${other_action.name}')
				postgresql_obj.start()!
			}

			if other_action.name == 'stop' {
				console.print_debug('install action postgresql.${other_action.name}')
				postgresql_obj.stop()!
			}
			if other_action.name == 'restart' {
				console.print_debug('install action postgresql.${other_action.name}')
				postgresql_obj.restart()!
			}
		}
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////# LIVE CYCLE MANAGEMENT FOR INSTALLERS ///////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

fn startupmanager_get(cat zinit.StartupManagerType) !startupmanager.StartupManager {
	// unknown
	// screen
	// zinit
	// tmux
	// systemd
	match cat {
		.zinit {
			console.print_debug('startupmanager: zinit')
			return startupmanager.get(cat: .zinit)!
		}
		.systemd {
			console.print_debug('startupmanager: systemd')
			return startupmanager.get(cat: .systemd)!
		}
		else {
			console.print_debug('startupmanager: auto')
			return startupmanager.get()!
		}
	}
}

// load from disk and make sure is properly intialized
pub fn (mut self Postgresql) reload() ! {
	switch(self.name)
	self = obj_init(self)!
}

pub fn (mut self Postgresql) start() ! {
	switch(self.name)
	if self.running()! {
		return
	}

	console.print_header('postgresql start')

	if !installed()! {
		install()!
	}

	configure()!

	start_pre()!

	for zprocess in startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!

		console.print_debug('starting postgresql with ${zprocess.startuptype}...')

		sm.new(zprocess)!

		sm.start(zprocess.name)!
	}

	start_post()!

	for _ in 0 .. 50 {
		if self.running()! {
			return
		}
		time.sleep(100 * time.millisecond)
	}
	return error('postgresql did not install properly.')
}

pub fn (mut self Postgresql) install_start(args InstallArgs) ! {
	switch(self.name)
	self.install(args)!
	self.start()!
}

pub fn (mut self Postgresql) stop() ! {
	switch(self.name)
	stop_pre()!
	for zprocess in startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!
		sm.stop(zprocess.name)!
	}
	stop_post()!
}

pub fn (mut self Postgresql) restart() ! {
	switch(self.name)
	self.stop()!
	self.start()!
}

pub fn (mut self Postgresql) running() !bool {
	switch(self.name)

	// walk over the generic processes, if not running return
	for zprocess in startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!
		r := sm.running(zprocess.name)!
		if r == false {
			return false
		}
	}
	return running()!
}

@[params]
pub struct InstallArgs {
pub mut:
	reset bool
}

pub fn (mut self Postgresql) install(args InstallArgs) ! {
	switch(self.name)
	if args.reset || (!installed()!) {
		install()!
	}
}

pub fn (mut self Postgresql) destroy() ! {
	switch(self.name)
	self.stop() or {}
	destroy()!
}

// switch instance to be used for postgresql
pub fn switch(name string) {
	postgresql_default = name
}
