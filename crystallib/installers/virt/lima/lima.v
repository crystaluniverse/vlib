module lima

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.installers.base
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.installers.virt.qemu
import os

@[params]
pub struct InstallArgs {
pub mut:
	reset     bool
	uninstall bool
}

pub fn install(args_ InstallArgs) ! {
	mut args := args_
	version := '0.22.0'

	if args.reset || args.uninstall {
		console.print_header('uninstall lima')
		uninstall()!
		console.print_debug(' - ok')
		if args.uninstall {
			return
		}
	}
	console.print_header('install install lima')

	base.install()!

	res := os.execute('${osal.profile_path_source_and()} lima -v')
	if res.exit_code == 0 {
		r := res.output.split_into_lines().filter(it.contains('limactl version'))
		if r.len != 1 {
			return error("couldn't parse lima version, expected 'lima version' on 1 row.\n${res.output}")
		}

		v := texttools.version(r[0].all_after('version'))
		if v < texttools.version(version) {
			args.reset = true
		}
	} else {
		args.reset = true
	}

	if args.reset == false {
		return
	}

	if args.reset {
		console.print_header('install lima')
		qemu.install()!
		mut url := ''
		mut dest_on_os := '${os.home_dir()}/hero'
		if osal.is_linux_arm() {
			dest_on_os = '/usr/local'
			url = 'https://github.com/lima-vm/lima/releases/download/v${version}/lima-${version}-Linux-aarch64.tar.gz'
		} else if osal.is_linux_intel() {
			dest_on_os = '/usr/local'
			url = 'https://github.com/lima-vm/lima/releases/download/v${version}/lima-${version}-Linux-x86_64.tar.gz'
		} else if osal.is_osx() {
			osx_install()!
			// } else if osal.is_osx_arm() {
			// 	url = 'https://github.com/lima-vm/lima/releases/download/v${version}/lima-${version}-Darwin-arm64.tar.gz'
			// } else if osal.is_osx_intel() {
			// 	url = 'https://github.com/lima-vm/lima/releases/download/v${version}/lima-${version}-Darwin-x86_64.tar.gz'
		} else {
			return error('unsported platform')
		}

		console.print_header('download ${url}')
		osal.download(
			url:         url
			minsize_kb:  45000
			reset:       args.reset
			dest:        '/tmp/lima.tar.gz'
			expand_file: '/tmp/download/lima'
		)!

		cmd := '
		rsync -rv /tmp/download/lima/ ${dest_on_os}
		'
		osal.exec(cmd: cmd)!
	}
}

@[params]
pub struct ExtensionsInstallArgs {
pub mut:
	extensions string
	default    bool = true
}

pub fn exists() !bool {
	e := osal.cmd_exists_profile('limactl')
	if e {
		console.print_header('lima already installed')
	}
	return e
}

pub fn uninstall() ! {
	cmd := '
	// # Quit Google Chrome
	// osascript -e \'quit app "Google Chrome"\'

	// # Wait a bit to ensure Chrome has completely quit
	// sleep 2

	'
	osal.exec(cmd: cmd)!
}

pub fn osx_install() ! {
	osal.package_install('lima')!
}
