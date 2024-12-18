module meilisearchinstaller

import freeflowuniverse.crystallib.core.base
import freeflowuniverse.crystallib.core.playbook
import freeflowuniverse.crystallib.sysadmin.startupmanager
import freeflowuniverse.crystallib.osal.zinit
import freeflowuniverse.crystallib.ui.console
import time

__global (
	meilisearchinstaller_global  map[string]&MeilisearchServer
	meilisearchinstaller_default string
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
		args.name = meilisearchinstaller_default
	}
	if args.name == '' {
		args.name = 'default'
	}
	return args
}

pub fn get(args_ ArgsGet) !&MeilisearchServer {
	mut args := args_get(args_)
	if args.name !in meilisearchinstaller_global {
		if args.name == 'default' {
			if !config_exists(args) {
				if default {
					config_save(args)!
				}
			}
			config_load(args)!
		}
	}
	return meilisearchinstaller_global[args.name] or {
		println(meilisearchinstaller_global)
		panic('could not get config for meilisearchinstaller with name:${args.name}')
	}
}

fn config_exists(args_ ArgsGet) bool {
	mut args := args_get(args_)
	mut context := base.context() or { panic('bug') }
	return context.hero_config_exists('meilisearchinstaller', args.name)
}

fn config_load(args_ ArgsGet) ! {
	mut args := args_get(args_)
	mut context := base.context()!
	mut heroscript := context.hero_config_get('meilisearchinstaller', args.name)!
	play(heroscript: heroscript)!
}

fn config_save(args_ ArgsGet) ! {
	mut args := args_get(args_)
	mut context := base.context()!
	context.hero_config_set('meilisearchinstaller', args.name, heroscript_default()!)!
}

fn set(o MeilisearchServer) ! {
	mut o2 := obj_init(o)!
	meilisearchinstaller_global[o.name] = &o2
	meilisearchinstaller_default = o.name
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

	mut install_actions := plbook.find(filter: 'meilisearchinstaller.configure')!
	if install_actions.len > 0 {
		for install_action in install_actions {
			mut p := install_action.params
			mycfg := cfg_play(p)!
			console.print_debug('install action meilisearchinstaller.configure\n${mycfg}')
			set(mycfg)!
		}
	}

	mut other_actions := plbook.find(filter: 'meilisearchinstaller.')!
	for other_action in other_actions {
		if other_action.name in ['destroy', 'install', 'build'] {
			mut p := other_action.params
			reset := p.get_default_false('reset')
			if other_action.name == 'destroy' || reset {
				console.print_debug('install action meilisearchinstaller.destroy')
				destroy()!
			}
			if other_action.name == 'install' {
				console.print_debug('install action meilisearchinstaller.install')
				install()!
			}
		}
		if other_action.name in ['start', 'stop', 'restart'] {
			mut p := other_action.params
			name := p.get('name')!
			mut meilisearchinstaller_obj := get(name: name)!
			console.print_debug('action object:\n${meilisearchinstaller_obj}')
			if other_action.name == 'start' {
				console.print_debug('install action meilisearchinstaller.${other_action.name}')
				meilisearchinstaller_obj.start()!
			}

			if other_action.name == 'stop' {
				console.print_debug('install action meilisearchinstaller.${other_action.name}')
				meilisearchinstaller_obj.stop()!
			}
			if other_action.name == 'restart' {
				console.print_debug('install action meilisearchinstaller.${other_action.name}')
				meilisearchinstaller_obj.restart()!
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
pub fn (mut self MeilisearchServer) reload() ! {
	switch(self.name)
	self = obj_init(self)!
}

pub fn (mut self MeilisearchServer) start() ! {
	switch(self.name)
	if self.running()! {
		return
	}

	console.print_header('meilisearchinstaller start')

	if !installed()! {
		install()!
	}

	configure()!

	start_pre()!

	for zprocess in startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!

		console.print_debug('starting meilisearchinstaller with ${zprocess.startuptype}...')

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
	return error('meilisearchinstaller did not install properly.')
}

pub fn (mut self MeilisearchServer) install_start(args InstallArgs) ! {
	switch(self.name)
	self.install(args)!
	self.start()!
}

pub fn (mut self MeilisearchServer) stop() ! {
	switch(self.name)
	stop_pre()!
	for zprocess in startupcmd()! {
		mut sm := startupmanager_get(zprocess.startuptype)!
		sm.stop(zprocess.name)!
	}
	stop_post()!
}

pub fn (mut self MeilisearchServer) restart() ! {
	switch(self.name)
	self.stop()!
	self.start()!
}

pub fn (mut self MeilisearchServer) running() !bool {
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

pub fn (mut self MeilisearchServer) install(args InstallArgs) ! {
	switch(self.name)
	if args.reset || (!installed()!) {
		install()!
	}
}

pub fn (mut self MeilisearchServer) build() ! {
	switch(self.name)
	build()!
}

pub fn (mut self MeilisearchServer) destroy() ! {
	switch(self.name)
	self.stop() or {}
	destroy()!
}

// switch instance to be used for meilisearchinstaller
pub fn switch(name string) {
	meilisearchinstaller_default = name
}
