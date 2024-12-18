module coredns

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.osal.screen
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.clients.httpconnection
import os

@[params]
pub struct InstallArgs {
pub mut:
	reset         bool // this means we re-install and forgot what we did before
	start         bool = true
	stop          bool
	restart       bool     // this means we stop if started, otherwise just start
	homedir       string   // not sure what this is?
	config_path   string   // path to Corefile, if empty will install default one
	config_url    string   // path to Corefile through e.g. git url, will pull it if it is not local yet
	dnszones_path string   // path to where all the dns zones are
	dnszones_url  string   // path on git url pull if needed
	plugins       []string // list of plugins to build CoreDNS with
	example       bool     // if true we will install examples
}

pub fn install(args_ InstallArgs) ! {
	mut args := args_
	version := '1.11.1'

	res := os.execute('${osal.profile_path_source_and()} coredns version')
	if res.exit_code == 0 {
		r := res.output.split_into_lines().filter(it.trim_space().starts_with('CoreDNS-'))
		if r.len != 1 {
			return error("couldn't parse coredns version.\n${res.output}")
		}
		if texttools.version(version) > texttools.version(r[0].all_after_first('CoreDNS-')) {
			args.reset = true
		}
	} else {
		args.reset = true
	}

	if args.reset {
		console.print_header('install coredns')

		mut url := ''
		if osal.is_linux_arm() {
			url = 'https://github.com/coredns/coredns/releases/download/v${version}/coredns_${version}_linux_arm64.tgz'
		} else if osal.is_linux_intel() {
			url = 'https://github.com/coredns/coredns/releases/download/v${version}/coredns_${version}_linux_amd64.tgz'
		} else if osal.is_osx_arm() {
			url = 'https://github.com/coredns/coredns/releases/download/v${version}/coredns_${version}_darwin_arm64.tgz'
		} else if osal.is_osx_intel() {
			url = 'https://github.com/coredns/coredns/releases/download/v${version}/coredns_${version}_darwin_amd64.tgz'
		} else {
			return error('unsported platform')
		}

		mut dest := osal.download(
			url:        url
			minsize_kb: 13000
			expand_dir: '/tmp/coredns'
		)!

		mut binpath := dest.file_get('coredns')!
		osal.cmd_add(
			cmdname: 'coredns'
			source:  binpath.path
		)!
	}

	configure(args)!

	if args.example {
		example_configure(args)!
	}

	if args.restart {
		restart(args)!
		return
	}

	if args.start {
		start(args)!
	}
}

pub fn restart(args_ InstallArgs) ! {
	stop(args_)!
	start(args_)!
}

pub fn stop(args_ InstallArgs) ! {
	console.print_header('coredns stop')

	name := 'coredns'

	// use startup manager, see caddy
	mut scr := screen.new()!
	scr.kill(name)!
}

pub fn start(args_ InstallArgs) ! {
	mut args := args_
	configure(args)!

	if check()! {
		return
	}

	console.print_header('coredns start')

	name := 'coredns'

	mut scr := screen.new()!

	mut s := scr.add(name: name, reset: true)!

	cmd2 := "coredns -conf '${args.config_path}'"

	s.cmd_send(cmd2)!

	if !check()! {
		return error("coredns did not install propertly, do: curl 'http://localhost:3334/health'")
	}

	console.print_header('coredns running')
}

pub fn check() !bool {
	// this checks health of coredns
	mut conn := httpconnection.new(name: 'coredns', url: 'http://localhost:3334')!
	r := conn.get(prefix: 'health')!
	if r.trim_space() == 'OK' {
		return true
	}
	return false
}
