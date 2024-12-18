module zitadel

import freeflowuniverse.crystallib.installers.zinit as zinitinstaller
import freeflowuniverse.crystallib.installers.base
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.ui.console

pub fn install() ! {
	if osal.platform() != .ubuntu {
		return error('only support ubuntu for now')
	}

	if osal.done_exists('zitadel_install') {
		console.print_header('zitadel binaraies already installed')
		return
	}

	// make sure we install base on the node
	base.install()!
	zinitinstaller.install()!

	version := '2.41.4'
	url := 'https://github.com/zitadel/zitadel/releases/download/v${version}/zitadel-linux-amd64.tar.gz'
	console.print_debug(' download ${url}')
	mut dest := osal.download(
		url:         url
		minsize_kb:  30000
		reset:       true
		expand_file: '/tmp/download/zitadel'
	)!

	binpath := pathlib.get_file(
		path:   '/tmp/download/zitadel/zitadel-linux-amd64/zitadel'
		create: false
	)!
	osal.cmd_add(
		cmdname: 'zitadel'
		source:  binpath.path
	)!

	osal.done_set('zitadel_install', 'OK')!

	console.print_header('zitadel installed properly.')
}
