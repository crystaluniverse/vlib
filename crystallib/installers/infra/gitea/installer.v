module gitea

import freeflowuniverse.crystallib.installers.db.postgresql as postgresinstaller
import freeflowuniverse.crystallib.installers.base
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.ui.console

pub fn install() ! {
	if osal.platform() != .ubuntu || osal.platform() != .arch {
		return error('only support ubuntu and arch for now')
	}

	if osal.done_exists('gitea_install') {
		console.print_header('gitea binaraies already installed')
		return
	}

	// make sure we install base on the node
	base.install()!
	postgresinstaller.install()!

	version := '1.22.0'
	url := 'https://github.com/go-gitea/gitea/releases/download/v${version}/gitea-${version}-linux-amd64.xz'
	console.print_debug(' download ${url}')
	mut dest := osal.download(
		url:         url
		minsize_kb:  40000
		reset:       true
		expand_file: '/tmp/download/gitea'
	)!

	binpath := pathlib.get_file(path: '/tmp/download/gitea', create: false)!
	osal.cmd_add(
		cmdname: 'gitea'
		source:  binpath.path
	)!

	osal.done_set('gitea_install', 'OK')!

	console.print_header('gitea installed properly.')
}

pub fn start() ! {
	if osal.platform() != .ubuntu || osal.platform() != .arch {
		return error('only support ubuntu and arch for now')
	}

	if osal.done_exists('gitea_install') {
		console.print_header('gitea binaraies already installed')
		return
	}

	// make sure we install base on the node
	base.install()!
	postgresinstaller.install()!

	version := '1.22.0'
	url := 'https://github.com/go-gitea/gitea/releases/download/v${version}/gitea-${version}-linux-amd64.xz'
	console.print_debug(' download ${url}')
	mut dest := osal.download(
		url:         url
		minsize_kb:  40000
		reset:       true
		expand_file: '/tmp/download/gitea'
	)!

	binpath := pathlib.get_file(path: '/tmp/download/gitea', create: false)!
	osal.cmd_add(
		cmdname: 'gitea'
		source:  binpath.path
	)!

	osal.done_set('gitea_install', 'OK')!

	console.print_header('gitea installed properly.')
}
