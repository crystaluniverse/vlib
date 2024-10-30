module vlang

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.ui.console
import os
import freeflowuniverse.crystallib.installers.base
import freeflowuniverse.crystallib.develop.gittools
// import freeflowuniverse.crystallib.sysadmin.downloader

pub fn install(args_ InstallArgs) ! {
	mut args := args_
	version := '0.4.8'
	console.print_header('install vlang (reset: ${args.reset})')
	res := os.execute('${osal.profile_path_source_and()} v --version')
	if res.exit_code == 0 {
		r := res.output.split_into_lines().filter(it.trim_space().starts_with('V'))
		if r.len != 1 {
			return error("couldn't parse v version.\n${res.output}")
		}
		myversion := r[0].all_after_first('V ').all_before(' ').trim_space()
		console.print_debug("V version: '${myversion}'")
		if texttools.version(version) > texttools.version(myversion) {
			// println(texttools.version(version))
			// println(texttools.version(myversion))
			// if true{panic("s")}
			args.reset = true
		}
	} else {
		args.reset = true
	}

	// install vlang if it was already done will return true
	if args.reset == false {
		return
	}

	base.develop()!

	mut gs := gittools.get(coderoot: '${os.home_dir()}/_code')!
	mut repo := gs.get_repo(
		pull: true
		reset: true
		url: 'https://github.com/vlang/v/tree/master'
	)!

	mut path1 := repo.get_path()!

	mut extra := ''
	if osal.is_linux() {
		extra = './v symlink'
	} else {
		extra = 'cp v ${os.home_dir()}/bin/'
	}
	cmd := '
	cd ${path1}
	make	
	${extra}
	'
	console.print_header('compile')
	osal.exec(cmd: cmd, stdout: true)!
	console.print_header('compile done')

	osal.done_set('install_vlang', 'OK')!
	return
}

@[params]
pub struct InstallArgs {
pub mut:
	reset bool
}
