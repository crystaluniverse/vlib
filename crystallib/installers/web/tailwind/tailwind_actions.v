module tailwind

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.core.pathlib
import os

pub const version = '3.4.12'

// checks if a certain version or above is installed
fn installed() !bool {
	res := os.execute('tailwind -h')
	if res.exit_code == 0 {
		r := res.output.split_into_lines().filter(it.contains('tailwindcss v'))
		if r.len != 1 {
			return error("couldn't parse tailwind version, expected 'tailwindcss v' on 1 row.\n${res.output}")
		}

		v := texttools.version(r[0].all_after(' '))
		if v < texttools.version(version) {
			return false
		}
		return true
	}
	return false
}

pub fn install() ! {
	console.print_header('install tailwind')

	mut url := ''
	if osal.is_linux_arm() {
		url = 'https://github.com/tailwindlabs/tailwindcss/releases/download/v${version}/tailwindcss-linux-arm64'
	} else if osal.is_linux_intel() {
		url = 'https://github.com/tailwindlabs/tailwindcss/releases/download/v${version}/tailwindcss-linux-x64'
	} else if osal.is_osx_arm() {
		url = 'https://github.com/tailwindlabs/tailwindcss/releases/download/v${version}/tailwindcss-macos-arm64'
	} else if osal.is_osx_intel() {
		url = 'https://github.com/tailwindlabs/tailwindcss/releases/download/v${version}/tailwindcss-macos-x64'
	} else {
		return error('unsported platform')
	}

	mut dest := osal.download(
		url:        url
		minsize_kb: 40000
		// reset: true
	)!

	osal.cmd_add(
		cmdname: 'tailwind'
		source:  dest.path
	)!
}

fn destroy() ! {
}
