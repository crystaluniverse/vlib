module fungistor

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
	version := '2.0.6'

	res := os.execute('rfs --version')
	if res.exit_code == 0 {
		r := res.output.trim_space().split(' ')
		if r.len != 2 {
			return error("couldn't parse rfs version.\n${res.output}")
		}

		if texttools.version(version) > texttools.version(r[1]) {
			args.reset = true
		}
	} else {
		args.reset = true
	}

	if args.reset == false {
		return
	}

	console.print_header('install rfs')

	mut url := ''
	if osal.is_linux_intel() {
		url = 'https://github.com/threefoldtech/rfs/releases/download/v${version}/rfs'
	} else {
		return error('unsported platform')
	}

	mut dest := osal.download(
		url:        url
		minsize_kb: 9000
		dest:       '/tmp/rfs'
		reset:      true
	)!

	osal.cmd_add(
		cmdname: 'rfs'
		source:  '${dest.path}'
	)!
}
