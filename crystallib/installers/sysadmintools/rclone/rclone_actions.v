module rclone

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.clients.httpconnection
import os

// checks if a certain version or above is installed
fn installed() !bool {
	res := os.execute('${osal.profile_path_source_and()} rclone version')
	if res.exit_code != 0 {
		return false
	}
	r := res.output.split_into_lines().filter(it.contains('rclone v'))
	if r.len != 1 {
		return error("couldn't parse rclone version, expected 'rclone 0' on 1 row.\n${res.output}")
	}
	v := texttools.version(r[0].all_after('rclone'))
	if texttools.version(version) > v {
		return false
	}
	return true
}

fn install() ! {
	console.print_header('install rclone')
	// THIS IS EXAMPLE CODEAND NEEDS TO BE CHANGED
	mut url := ''
	if osal.is_linux_arm() {
		url = 'https://github.com/rclone/rclone/releases/download/v${version}/rclone-v${version}-linux-arm64.zip'
	} else if osal.is_linux_intel() {
		url = 'https://github.com/rclone/rclone/releases/download/v${version}/rclone-v${version}-linux-amd64.zip'
	} else if osal.is_osx_arm() {
		url = 'https://downloads.rclone.org/rclone-current-osx-amd64.zip'
	} else if osal.is_osx_intel() {
		url = 'https://github.com/rclone/rclone/releases/download/v${version}/rclone-v${version}-osx-amd64.zip'
	} else {
		return error('unsported platform')
	}

	mut dest := osal.download(
		url:        url
		minsize_kb: 9000
		expand_dir: '/tmp/rclone'
	)!
	// dest.moveup_single_subdir()!
	mut binpath := dest.file_get('rclone')!
	osal.cmd_add(
		cmdname: 'rclone'
		source:  binpath.path
	)!
}

fn configure() ! {
	_ := get()!

	// THIS IS EXAMPLE CODEAND NEEDS TO BE CHANGED

	_ := $tmpl('templates/rclone.yaml')
	// mut path := pathlib.get_file(path: cfg.configpath, create: true)!
	// path.write(mycode)!
	// console.print_debug(mycode)
	// implement if steps need to be done for configuration
}

fn destroy() ! {
}

fn start_pre() ! {
}

fn start_post() ! {
}

fn stop_pre() ! {
}

fn stop_post() ! {
}
