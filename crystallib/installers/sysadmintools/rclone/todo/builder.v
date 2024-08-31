module rclone

import freeflowuniverse.crystallib.installers.lang.golang
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.develop.gittools
import freeflowuniverse.crystallib.ui.console

const url = 'https://github.com/rclone/rclone'

@[params]
pub struct BuildArgs {
pub mut:
	reset    bool
	bin_push bool = true
}

// install rclone will return true if it was already installed
pub fn build(args BuildArgs) ! {
	// make sure we install base on the node
	if osal.platform() != .ubuntu {
		return error('only support ubuntu for now')
	}
	golang.install()!

	// install rclone if it was already done will return true
	console.print_header('build rclone')

	gitpath := gittools.code_get(coderoot: '/tmp/builder', url: rclone.url, reset: true, pull: true)!

	cmd := '

	cd ${gitpath}
	exit 1 #todo
	'
	osal.execute_stdout(cmd)!

	// if args.bin_push {
	// 	installers.bin_push(
	// 		cmdname: 'rclone'
	// 		source: '/tmp/builder/github/threefoldtech/rclone/target/x86_64-unknown-linux-musl/release/rclone'
	// 	)!
	// }
}
