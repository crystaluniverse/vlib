module actrunner

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
	version := '0.2.10'

	res := os.execute('${osal.profile_path_source_and()} actrunner -v')
	if res.exit_code == 0 {
		r := res.output.split_into_lines().filter(it.contains('act_runner version'))
		if r.len != 1 {
			return error("couldn't parse actrunner version, expected 'actrunner 0' on 1 row.\n${res.output}")
		}

		v := texttools.version(r[0].all_after('act_runner version'))
		if v < texttools.version(version) {
			args.reset = true
		}
	} else {
		args.reset = true
	}

	if args.reset == false {
		return
	}

	console.print_header('install actrunner')

	mut url := ''
	if osal.is_linux_arm() {
		url = 'https://dl.gitea.com/act_runner/${version}/act_runner-${version}-linux-arm64'
	} else if osal.is_linux_intel() {
		url = 'https://dl.gitea.com/act_runner/${version}/act_runner-${version}-linux-amd64'
	} else if osal.is_osx_arm() {
		url = 'https://dl.gitea.com/act_runner/${version}/act_runner-${version}-darwin-arm64'
	} else if osal.is_osx_intel() {
		url = 'https://dl.gitea.com/act_runner/${version}/act_runner-${version}-darwin-amd64'
	} else {
		return error('unsported platform')
	}

	mut dest := osal.download(
		url:        url
		minsize_kb: 15000
	)!

	// console.print_debug(dest)

	osal.cmd_add(
		cmdname: 'actrunner'
		source:  dest.path
	)!

	return
}
