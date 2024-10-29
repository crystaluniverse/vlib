module yggdrasil

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.installers.lang.golang
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.osal.screen
import freeflowuniverse.crystallib.ui
import freeflowuniverse.crystallib.develop.gittools
import os
import time

@[params]
pub struct InstallArgs {
pub mut:
	reset bool
}

// install yggdrasil will return true if it was already installed
pub fn install(args_ InstallArgs) ! {
	peers := '
Peers:
  [
    tcp://45.138.172.192:5001
    tcp://94.130.203.208:5999
    tcp://185.69.166.140:9943
    tcp://185.69.166.141:9943
    tcp://185.69.167.141:9943
    tcp://185.69.167.142:9943
    tcp://185.206.122.31:9943
    tcp://185.206.122.32:9943
    tcp://185.206.122.131:9943
    tcp://185.206.122.132:9943
    tls://140.238.168.104:17121
    tls://s2.i2pd.xyz:39575
    tcp://62.210.85.80:39565
  ]

	'
	config_path := '/etc/yggdrasil.conf'
	mut args := args_

	res := os.execute('${osal.profile_path_source_and()} yggdrasil -version')
	if res.exit_code != 0 {
		args.reset = true
	}

	if args.reset {
		golang.install()!
		console.print_header('install yggdrasil')
		mut gs := gittools.get(coderoot: '${os.home_dir()}/_code')!
		mut repo := gs.get_repo(
			url: 'https://github.com/yggdrasil-network/yggdrasil-go.git'
			reset: false
		)!

		mut path := repo.get_path()!

		osal.exec(cmd: 'cd ${path} && PATH=\$PATH:/usr/local/go/bin ./build')!

		osal.cmd_add(
			source: '${path}/yggdrasil'
		)!
		osal.cmd_add(
			source: '${path}/yggdrasilctl'
		)!

		osal.cmd_add(
			source: '${path}/contrib/docker/entrypoint.sh'
		)!
		if !os.exists(config_path) {
			osal.exec(cmd: 'yggdrasil -genconf > /etc/yggdrasil.conf')!
			config := os.read_file(config_path)!
			config.replace('Peers: []', peers)
		}
	}
}

pub fn restart() ! {
	name := 'yggdrasil'
	mut scr := screen.new(reset: false)!
	scr.kill(name)!
	start()!
}

pub fn start() ! {
	// console.print_debug("start")

	mut scr := screen.new(reset: false)!
	name := 'yggdrasil'

	if scr.exists(name) {
		console.print_header('yggdrasil was already running')
		return
	}

	mut s := scr.add(name: name, start: true)!

	mut cmd2 := ''

	if osal.is_osx() {
		cmd2 = 'sudo -s '
	}

	cmd2 += 'yggdrasil --useconf < "/etc/yggdrasil.conf"'

	s.cmd_send(cmd2)!

	console.print_debug(s)

	console.print_debug('send done')

	if osal.is_osx() {
		mut myui := ui.new()!
		console.clear()

		console.print_stderr("
		On the next screen you will be able to fill in your password.
		Once done and the server is started: do 'control a + control d'
		
		")

		_ = myui.ask_yesno(question: 'Please confirm you understand?')!

		s.attach()! // to allow filling in passwd
	}

	console.print_header('yggdrasil is running')

	time.sleep(100 * time.millisecond)

	if !running()! {
		return error('cound not start yggdrasil')
	}
}

pub fn running() !bool {
	mut scr := screen.new(reset: false)!
	name := 'yggdrasil'

	if !scr.exists(name) {
		return false
	}

	if !(osal.process_exists_byname('yggdrasil')!) {
		return false
	}

	return true
}
