module startupmanager

import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.osal.screen
import freeflowuniverse.crystallib.osal.systemd
import freeflowuniverse.crystallib.osal.zinit

// // TODO: check if using this interface would simplify things
// pub interface StartupManagerI {
// 	new(args zinit.ZProcessNewArgs)!
// 	start(name string)!
// 	stop(name string)!
// 	restart(name string)!
// 	delete(name string)!
// 	status(name string) !ProcessStatus
// 	running(name string) !bool
// 	output(name string) !string
// 	exists(name string) !bool
// 	list_services() ![]string
// }

pub enum StartupManagerType {
	unknown
	screen
	zinit
	tmux
	systemd
}

pub struct StartupManager {
pub mut:
	cat StartupManagerType
}

@[params]
pub struct StartupManagerArgs {
pub mut:
	cat StartupManagerType
}

pub fn get(args StartupManagerArgs) !StartupManager {
	mut sm := StartupManager{
		cat: args.cat
	}
	if args.cat == .unknown {
		if zinit.check() {
			sm.cat = .zinit
		} else if systemd.check()! {
			sm.cat = .systemd
		}
	}
	return sm
}

// launch a new process
//```
// name        string            @[required]
// cmd         string            @[required]
// cmd_stop    string
// cmd_test    string 		//command line to test service is running
// status  ZProcessStatus
// pid     int
// after   []string 	//list of service we depend on
// env     map[string]string
// oneshot bool
// start 	  bool = true
// restart     bool = true // whether the process should be restarted on failure
// description string //not used in zinit
//```
pub fn (mut sm StartupManager) new(args zinit.ZProcessNewArgs) ! {
	console.print_debug("startupmanager start:${args.name} cmd:'${args.cmd}' restart:${args.restart}")
	mut mycat := sm.cat
	if args.startuptype == .systemd {
		mycat = .systemd
	}
	match mycat {
		.screen {
			mut scr := screen.new(reset: false)!
			console.print_debug('screen')
			_ = scr.add(name: args.name, cmd: args.cmd, reset: args.restart)!
		}
		.systemd {
			console.print_debug('systemd start  ${args.name}')
			mut systemdfactory := systemd.new()!
			systemdfactory.new(
				cmd:         args.cmd
				name:        args.name
				description: args.description
				start:       args.start
				restart:     args.restart
				env:         args.env
			)!
		}
		.zinit {
			console.print_debug('zinit start ${args.name}')
			mut zinitfactory := zinit.new()!
			// pub struct ZProcessNewArgs {
			// 	name      string            @[required]
			// 	cmd       string            @[required]
			// 	cmd_stop       string
			// 	cmd_test       string
			// 	cmd_file  bool // if we wanna force to run it as a file which is given to bash -c  (not just a cmd in zinit)
			// 	test      string
			// 	test_file bool
			// 	after     []string
			// 	env       map[string]string
			// 	oneshot   bool
			// }
			zinitfactory.new(args)!
		}
		else {
			panic('to implement, startup manager only support screen & systemd for now')
		}
	}
	// if args.start {
	// 	sm.start(args.name)!
	// } else if args.restart {
	// 	sm.restart(args.name)!
	// }
}

pub fn (mut sm StartupManager) start(name string) ! {
	match sm.cat {
		.screen {
			return
		}
		.systemd {
			console.print_debug('systemd process start ${name}')
			mut systemdfactory := systemd.new()!
			if systemdfactory.exists(name) {
				// console.print_header("*************")
				mut systemdprocess := systemdfactory.get(name)!
				systemdprocess.start()!
			} else {
				return error('process in systemd with name ${name} not found')
			}
		}
		.zinit {
			console.print_debug('zinit process start ${name}')
			mut zinitfactory := zinit.new()!
			zinitfactory.start(name)!
		}
		else {
			panic('to implement, startup manager only support screen for now')
		}
	}
}

pub fn (mut sm StartupManager) stop(name string) ! {
	match sm.cat {
		.screen {
			mut screen_factory := screen.new(reset: false)!
			mut scr := screen_factory.get(name) or { return }
			scr.cmd_send('^C')!
			screen_factory.kill(name)!
		}
		.systemd {
			console.print_debug('systemd stop ${name}')
			mut systemdfactory := systemd.new()!
			if systemdfactory.exists(name) {
				mut systemdprocess := systemdfactory.get(name)!
				systemdprocess.stop()!
			}
		}
		.zinit {
			console.print_debug('zinit stop ${name}')
			mut zinitfactory := zinit.new()!
			zinitfactory.load()!
			if zinitfactory.exists(name) {
				zinitfactory.stop(name)!
			}
		}
		else {
			panic('to implement, startup manager only support screen for now')
		}
	}
}

// kill the process by name
pub fn (mut sm StartupManager) restart(name string) ! {
	match sm.cat {
		.screen {
			panic('implement')
		}
		.systemd {
			console.print_debug('systemd restart ${name}')
			mut systemdfactory := systemd.new()!
			mut systemdprocess := systemdfactory.get(name)!
			systemdprocess.restart()!
		}
		.zinit {
			console.print_debug('zinit restart ${name}')
			mut zinitfactory := zinit.new()!
			zinitfactory.stop(name)!
			zinitfactory.start(name)!
		}
		else {
			panic('to implement, startup manager only support screen for now')
		}
	}
}

// remove from the startup manager
pub fn (mut sm StartupManager) delete(name string) ! {
	match sm.cat {
		.screen {
			mut screen_factory := screen.new(reset: false)!
			mut scr := screen_factory.get(name) or { return }
			scr.cmd_send('^C')!
			screen_factory.kill(name)!
		}
		.systemd {
			mut systemdfactory := systemd.new()!
			mut systemdprocess := systemdfactory.get(name)!
			systemdprocess.delete()!
		}
		.zinit {
			mut zinitfactory := zinit.new()!
			zinitfactory.load()!
			if zinitfactory.exists(name) {
				zinitfactory.delete(name)!
			}
		}
		else {
			panic('to implement, startup manager only support screen & systemd for now')
		}
	}
}

pub enum ProcessStatus {
	unknown
	active
	inactive
	failed
	activating
	deactivating
}

// remove from the startup manager
pub fn (mut sm StartupManager) status(name string) !ProcessStatus {
	match sm.cat {
		.screen {
			mut screen_factory := screen.new(reset: false)!
			mut scr := screen_factory.get(name) or {
				return error('process with name ${name} not found')
			}
			match scr.status()! {
				.active { return .active }
				.inactive { return .inactive }
				.unknown { return .unknown }
			}
		}
		.systemd {
			mut systemdfactory := systemd.new()!
			mut systemdprocess := systemdfactory.get(name) or { return .unknown }
			systemd_status := systemdprocess.status() or {
				return error('Failed to get status of process ${name}\n${err}')
			}
			s := ProcessStatus.from(systemd_status.str())!
			return s
		}
		.zinit {
			mut zinitfactory := zinit.new()!
			mut p := zinitfactory.get(name) or { return .unknown }
			// unknown
			// init
			// ok
			// killed
			// error
			// blocked
			// spawned			
			match mut p.status()! {
				.init { return .activating }
				.ok { return .active }
				.error { return .failed }
				.blocked { return .inactive }
				.killed { return .inactive }
				.spawned { return .activating }
				.unknown { return .unknown }
			}
		}
		else {
			panic('to implement, startup manager only support screen & systemd for now')
		}
	}
}

pub fn (mut sm StartupManager) running(name string) !bool {
	if !sm.exists(name)! {
		return false
	}
	mut s := sm.status(name)!
	return s == .active
}

// remove from the startup manager
pub fn (mut sm StartupManager) output(name string) !string {
	match sm.cat {
		.screen {
			panic('implement')
		}
		.systemd {
			return systemd.journalctl(service: name)!
		}
		else {
			panic('to implement, startup manager only support screen & systemd for now')
		}
	}
}

pub fn (mut sm StartupManager) exists(name string) !bool {
	match sm.cat {
		.screen {
			mut scr := screen.new(reset: false) or { panic("can't get screen") }
			return scr.exists(name)
		}
		.systemd {
			// console.print_debug("exists sm systemd ${name}")
			mut systemdfactory := systemd.new()!
			return systemdfactory.exists(name)
		}
		.zinit {
			// console.print_debug("exists sm zinit check ${name}")
			mut zinitfactory := zinit.new()!
			zinitfactory.load()!
			return zinitfactory.exists(name)
		}
		else {
			panic('to implement. startup manager only support screen & systemd for now')
		}
	}
}

// list all services as known to the startup manager
pub fn (mut sm StartupManager) list() ![]string {
	match sm.cat {
		.screen {
			// mut scr := screen.new(reset: false) or { panic("can't get screen") }
			panic('implement')
		}
		.systemd {
			mut systemdfactory := systemd.new()!
			return systemdfactory.names()
		}
		.zinit {
			mut zinitfactory := zinit.new()!
			return zinitfactory.names()
		}
		else {
			panic('to implement. startup manager only support screen & systemd for now')
		}
	}
}

// THIS IS PROBABLY PART OF OTHER MODULE NOW

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
