module restic

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
	version := '0.16.2'

	res := os.execute('${osal.profile_path_source_and()} restic version')
	if res.exit_code == 0 {
		r := res.output.split_into_lines().filter(it.contains('restic 0'))
		if r.len != 1 {
			return error("couldn't parse restic version, expected 'restic 0' on 1 row.\n${res.output}")
		}

		v := texttools.version(r[0].all_before('compiled').all_after('restic'))
		if v < texttools.version(version) {
			args.reset = true
		}
	} else {
		args.reset = true
	}

	if args.reset == false {
		return
	}

	console.print_header('install restic')

	mut url := ''
	if osal.is_linux() {
		url = 'https://github.com/restic/restic/releases/download/v${version}/restic_${version}_linux_amd64.bz2'
	} else if osal.is_osx_arm() {
		url = 'https://github.com/restic/restic/releases/download/v${version}/restic_${version}_darwin_arm64.bz2'
	} else if osal.is_osx_intel() {
		url = 'https://github.com/restic/restic/releases/download/v${version}/restic_${version}_darwin_amd64.bz2'
	} else {
		return error('unsported platform')
	}

	mut dest := osal.download(
		url:         url
		minsize_kb:  7000
		expand_file: '/tmp/restic'
	)!

	// console.print_debug(dest)

	osal.cmd_add(
		cmdname: 'restic'
		source:  dest.path
	)!

	return
}
