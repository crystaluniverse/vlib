module zinit

import freeflowuniverse.crystallib.installers.base
import freeflowuniverse.crystallib.osal
// import freeflowuniverse.crystallib.osal.systemd
import freeflowuniverse.crystallib.ui.console
// import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.core.texttools
import os

@[params]
pub struct InstallArgs {
pub mut:
	reset bool
}

// install zinit will return true if it was already installed
pub fn install(args_ InstallArgs) ! {
	mut args := args_

	if !osal.is_linux() {
		return error('only support linux for now')
	}

	version := '0.2.14'
	// cmd:='${osal.profile_path_source_and()} zinit --version'
	cmd := 'zinit --version'
	// println(cmd)
	res := os.execute(cmd)
	if res.exit_code == 0 {
		r := res.output.split_into_lines().filter(it.trim_space().starts_with('zinit v'))
		if r.len != 1 {
			return error("couldn't parse zinit version.\n${res.output}")
		}
		if texttools.version(version) > texttools.version(r[0].all_after_first('zinit v')) {
			println('reset because of -v')
			args.reset = true
		}
	} else {
		println(res)
		println('reset of error in zinit execute')
		args.reset = true
	}

	if args.reset == false && osal.done_exists('install_zinit') {
		return
	}

	console.print_header('install zinit')
	// make sure we install base on the node
	base.install()!
	url := 'https://github.com/threefoldtech/zinit/releases/download/v0.2.14/zinit'

	mut dest := osal.download(
		url:        url
		minsize_kb: 2000
		reset:      true
	)!

	osal.cmd_add(
		cmdname: 'zinit'
		source:  dest.path
	)!

	console.print_header('install zinit done')

	start()!

	osal.done_set('install_zinit', 'OK')!
	return
}

// start zinit
pub fn start() ! {
	start()!
}

// pub fn stop() ! {
// }

// pub fn restart() ! {
// 	stop()!
// 	start()!
// }
