module startupmanager

// import freeflowuniverse.crystallib.osal
// import freeflowuniverse.crystallib.core.pathlib
// import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.ui.console
// import freeflowuniverse.crystallib.clients.redisclient
import freeflowuniverse.crystallib.osal.screen
import freeflowuniverse.crystallib.osal.systemd
import freeflowuniverse.crystallib.core.base
import json
import os
import rand

pub enum StartupManagerType {
	screen
	zinit
	tmux
	systemd
}

pub struct StartupManager {
pub mut:
	cat StartupManagerType
}

pub struct StartupManagerArgs {
pub mut:
	cat StartupManagerType
}

// pub fn configure(args StartupManagerArgs) ! {
// 	mut c := base.context()!
// 	mut r := c.redis()!
// 	mut d := json.encode_pretty(args)
// 	r.set('startupmanager', d)!
// }

pub fn get() !StartupManager {
	// mut c := base.context()!
	// mut r := c.redis()!
	// exists := r.exists('startupmanager')!
	// if !exists {
	// 	configure(cat: .screen)!
	// }
	// data := r.get('startupmanager')!
	// mut args := json.decode(StartupManagerArgs, data)!
	mut sm := StartupManager{}
	if systemd.check()!{
		sm.cat = .systemd
	}
	return sm
}

pub struct StartArgs {
pub mut:
	description string
	name  string @[requred]
	cmd   string
	reset bool
	// start  bool = true
	// attach bool
}

// launch a new process
//```
// name  string
// cmd   string
// reset bool
//```
pub fn (mut sm StartupManager) start(args StartArgs) ! {
	console.print_debug("startupmanager start:${args.name} cmd:'${args.cmd}' reset:${args.reset}")
	match sm.cat {
		.screen {
			mut scr := screen.new(reset: false)!
			console.print_debug("  screen")
			_ = scr.add(name: args.name, cmd: args.cmd, reset: args.reset)!
		}
		.systemd {
			console.print_debug("  systemd")

		}
		else {
			panic('to implement, startup manager only support screen & systemd for now')
		}
	}
}

// kill the process by name
pub fn (mut sm StartupManager) kill(name string) ! {
	match sm.cat {
		.screen {
			mut screen_factory := screen.new(reset: false)!
			mut scr := screen_factory.get(name) or {return}
			scr.cmd_send('^C')!
			screen_factory.kill(name)!
		}
		.systemd {

		}		
		else {
			panic('to implement, startup manager only support screen for now')
		}
	}
}

pub fn (mut sm StartupManager) exists(name string) bool {
	match sm.cat {
		.screen {
			mut scr := screen.new(reset: false) or { panic("can't get screen") }
			return scr.exists(name)
		}
		.systemd {
			return false
		}		
		else {
			panic('to implement. startup manager only support screen for now')
		}
	}
}

// pub struct SecretArgs {
// pub mut:
// 	name string     @[required]
// 	cat  SecretType
// }

// pub enum SecretType {
// 	normal
// }

// // creates a secret if it doesn exist yet
// pub fn (mut sm StartupManager) secret(args SecretArgs) !string {
// 	if !(sm.exists(args.name)) {
// 		return error("can't find screen with name ${args.name}, for secret")
// 	}
// 	key := 'secrets:startup:${args.name}'
// 	mut redis := redisclient.core_get()!
// 	mut secret := redis.get(key)!
// 	if secret.len == 0 {
// 		secret = rand.hex(16)
// 		redis.set(key, secret)!
// 	}
// 	return secret
// }
