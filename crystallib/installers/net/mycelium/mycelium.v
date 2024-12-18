module mycelium

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.installers.lang.rust
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.osal.screen
import freeflowuniverse.crystallib.ui
import freeflowuniverse.crystallib.sysadmin.startupmanager
import os
import time
import json

@[params]
pub struct InstallArgs {
pub mut:
	reset   bool
	restart bool = true
}

// install mycelium will return true if it was already installed
pub fn install(args_ InstallArgs) ! {
	mut args := args_

	console.print_header('install mycelium.')

	version := '0.5.6'

	res := os.execute('${osal.profile_path_source_and()} mycelium -V')
	if res.exit_code == 0 {
		r := res.output.split_into_lines().filter(it.trim_space().starts_with('mycelium'))
		if r.len != 1 {
			return error("couldn't parse mycelium version.\n${res.output}")
		}
		if texttools.version(version) > texttools.version(r[0].all_after_first('mycelium')) {
			args.reset = true
		}
	} else {
		args.reset = true
	}

	if args.reset {
		console.print_header('install mycelium')

		mut url := ''
		if osal.is_linux_arm() {
			url = 'https://github.com/threefoldtech/mycelium/releases/download/v${version}/mycelium-aarch64-unknown-linux-musl.tar.gz'
		} else if osal.is_linux_intel() {
			url = 'https://github.com/threefoldtech/mycelium/releases/download/v${version}/mycelium-x86_64-unknown-linux-musl.tar.gz'
		} else if osal.is_osx_arm() {
			url = 'https://github.com/threefoldtech/mycelium/releases/download/v${version}/mycelium-aarch64-apple-darwin.tar.gz'
		} else if osal.is_osx_intel() {
			url = 'https://github.com/threefoldtech/mycelium/releases/download/v${version}/mycelium-x86_64-apple-darwin.tar.gz'
		} else {
			return error('unsported platform')
		}
		// console.print_debug(url)
		mut dest := osal.download(
			url:        url
			minsize_kb: 1000
			reset:      true
			expand_dir: '/tmp/myceliumnet'
		)!

		mut myceliumfile := dest.file_get('mycelium')! // file in the dest

		// console.print_debug(myceliumfile.str())

		osal.cmd_add(
			source: myceliumfile.path
		)!
	}

	if args.restart {
		stop()!
	}
	start()!

	console.print_debug('install mycelium ok')
}

pub fn restart() ! {
	stop()!
	start()!
}

pub fn stop() ! {
	name := 'mycelium'
	console.print_debug('stop ${name}')
	if osal.is_osx() {
		mut scr := screen.new(reset: false)!
		scr.kill(name)!
	} else {
		mut sm := startupmanager.get()!
		sm.stop(name)!
	}
}

pub fn start(args InstallArgs) ! {
	if check() {
		console.print_header('mycelium was already running')
		return
	}
	myinitname := osal.initname()!
	name := 'mycelium'
	console.print_debug('start ${name} (startupmanger:${myinitname})')

	mut cmd := ''

	if osal.is_osx() {
		cmd = 'sudo -s '
	}

	cmd += 'mycelium --key-file ${osal.hero_path()!}/cfg/priv_key.bin --peers tcp://188.40.132.242:9651 quic://185.69.166.7:9651 tcp://65.21.231.58:9651 --tun-name utun9'
	console.print_debug(cmd)
	if osal.is_osx() {
		// do not change, because we need this on osx at least

		mut scr := screen.new(reset: false)!

		if scr.exists(name) {
			console.print_header('mycelium was already running')
			return
		}

		mut s := scr.add(name: name, start: true, reset: args.reset)!
		s.cmd_send(cmd)!

		mut myui := ui.new()!
		console.clear()

		console.print_stderr("
		On the next screen you will be able to fill in your password.
		Once done and the server is started: do 'control a + d'
		
		")

		_ = myui.ask_yesno(question: 'Please confirm you understand?')!

		s.attach()! // to allow filling in passwd		
	} else {
		mut sm := startupmanager.get()!
		sm.new(
			name:  name
			cmd:   cmd
			start: true
		)!
	}

	console.print_debug('startup manager started')

	time.sleep(100 * time.millisecond)

	if !check() {
		return error('cound not start mycelium')
	}

	console.print_header('mycelium is running')
}

pub fn check() bool {
	// if osal.is_osx() {
	// 	mut scr := screen.new(reset: false) or {return False}
	// 	name := 'mycelium'
	// 	if !scr.exists(name) {
	// 		return false
	// 	}
	// }

	// if !(osal.process_exists_byname('mycelium') or {return False}) {
	// 	return false
	// }

	// TODO: might be dangerous if that one goes out
	ping_result := osal.ping(address: '40a:152c:b85b:9646:5b71:d03a:eb27:2462', retry: 2) or {
		return false
	}
	if ping_result == .ok {
		console.print_debug('could reach 40a:152c:b85b:9646:5b71:d03a:eb27:2462')
		return true
	}
	console.print_stderr('could not reach 40a:152c:b85b:9646:5b71:d03a:eb27:2462')
	return false
}

// install mycelium will return true if it was already installed
pub fn build() ! {
	rust.install()!
	console.print_header('build mycelium')
	if !osal.done_exists('build_mycelium') && !osal.cmd_exists('mycelium') {
		panic('implement')
		// USE OUR PRIMITIVES (TODO, needs to change, was from zola)
		cmd := '
		source ~/.cargo/env
		cd /tmp
		rm -rf mycelium
		git clone https://github.com/getmycelium/mycelium.git
		cd mycelium
		cargo install --path . --locked
		mycelium --version
		cargo build --release --locked --no-default-features --features=native-tls
		cp target/release/mycelium ~/.cargo/bin/mycelium
		'
		osal.execute_stdout(cmd)!
		osal.done_set('build_mycelium', 'OK')!
		console.print_header('mycelium installed')
	} else {
		console.print_header('mycelium already installed')
	}
}

struct MyceliumInspectResult {
	public_key string @[json: publicKey]
	address    string
}

pub fn inspect() !MyceliumInspectResult {
	command := 'mycelium inspect --key-file /root/hero/cfg/priv_key.bin --json'
	result := os.execute(command)
	if result.exit_code != 0 {
		return error('Command failed: ${result.output}')
	}
	inspect_result := json.decode(MyceliumInspectResult, result.output) or {
		return error('Failed to parse JSON: ${err}')
	}
	return inspect_result
}

// if returns empty then probably mycelium is not installed
pub fn ipaddr() string {
	r := inspect() or { MyceliumInspectResult{} }
	return r.address
}
