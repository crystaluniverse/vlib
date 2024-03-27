module garage_s3

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.texttools
import os

@[params]
pub struct InstallArgs {
pub mut:
	reset bool
}

pub fn install(args_ InstallArgs) ! {
	mut args := args_
	version := '0.9.3'

	res := os.execute('garage --version')
	if res.exit_code == 0 {
		r := res.output.split(' ')
		if r.len < 2 {
			return error("couldn't parse garage version, expected 'garage v*'.\n${res.output}")
		}

		v := r[1]
		if texttools.version(v) < texttools.version(version) {
			args.reset = true
		}
	} else {
		args.reset = true
	}

	if args.reset == false {
		return
	}

	console.print_header('install garage')

	mut url := ''
	if osal.is_linux_arm() {
		url = 'https://garagehq.deuxfleurs.fr/_releases/v${version}/aarch64-unknown-linux-musl/garage'
	} else if osal.is_linux_intel() {
		url = 'https://garagehq.deuxfleurs.fr/_releases/v${version}/x86_64-unknown-linux-musl/garage'
	} else {
		return error('unsported platform')
	}

	mut dest := osal.download(
		url: url
		minsize_kb: 15 * 1024
		dest: '/tmp/garage'
		reset: true
	)!

	osal.cmd_add(
		cmdname: 'garage'
		source: '${dest.path}/garage_'
	)!

	return
}