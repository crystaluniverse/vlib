module caddy

import freeflowuniverse.crystallib.core.playbook
// import freeflowuniverse.crystallib.osal.zinit
import freeflowuniverse.crystallib.sysadmin.startupmanager
import freeflowuniverse.crystallib.ui.console
import time

@[params]
pub struct InstallPlayArgs {
pub mut:
	name       string = 'default'
	heroscript string // if filled in then plbook will be made out of it
	plbook     ?playbook.PlayBook
	reset      bool
	start      bool
	stop       bool
	restart    bool
	delete     bool
	configure  bool // make sure there is at least one installed
}

pub fn play(args_ InstallPlayArgs) ! {
	mut args := args_

	if args.heroscript == '' {
		args.heroscript = heroscript_default
	}
	mut plbook := args.plbook or { playbook.new(text: args.heroscript)! }

	mut install_actions := plbook.find(filter: 'caddy.configure')!
	if install_actions.len > 0 {
		for install_action in install_actions {
			mut p := install_action.params
			cfg_play(p)!
		}
	}
}

// load from disk and make sure is properly intialized
pub fn (mut self CaddyServer) reload() ! {
	switch(self.name)
	obj_init()!
}

pub fn (mut self CaddyServer) start() ! {
	switch(self.name)
	if self.running()! {
		return
	}

	console.print_header('caddy start')

	configure()!

	start_pre()!

	mut sm := startupmanager.get()!

	for zprocess in startupcmd()! {
		sm.start(zprocess.name)!
	}

	start_post()!

	for _ in 0 .. 50 {
		if self.running()! {
			return
		}
		time.sleep(100 * time.millisecond)
	}
	return error('caddy did not install properly.')
}

pub fn (mut self CaddyServer) install_start(args RestartArgs) ! {
	switch(self.name)
	self.install(args)!
	self.start()!
}

pub fn (mut self CaddyServer) stop() ! {
	switch(self.name)
	stop_pre()!
	mut sm := startupmanager.get()!
	for zprocess in startupcmd()! {
		sm.stop(zprocess.name)!
	}
	stop_post()!
}

pub fn (mut self CaddyServer) restart() ! {
	switch(self.name)
	self.stop()!
	self.start()!
}

pub fn (mut self CaddyServer) running() !bool {
	switch(self.name)
	mut sm := startupmanager.get()!

	// walk over the generic processes, if not running return
	for zprocess in startupcmd()! {
		r := sm.running(zprocess.name)!
		if r == false {
			return false
		}
	}
	return running()!
}

@[params]
pub struct RestartArgs {
pub mut:
	reset bool
}

pub fn (mut self CaddyServer) install(args RestartArgs) ! {
	switch(self.name)
	if args.reset || (!installed()!) {
		install()!
	}
}

pub fn (mut self CaddyServer) destroy() ! {
	switch(self.name)

	self.stop()!
	destroy()!
}
