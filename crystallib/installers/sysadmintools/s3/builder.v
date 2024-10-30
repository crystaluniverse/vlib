module s3

import freeflowuniverse.crystallib.installers.lang.rust
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.develop.gittools
import freeflowuniverse.crystallib.ui.console

@[params]
pub struct BuildArgs {
pub mut:
	reset bool
	// bin_push bool = true
}

// install s3cas will return true if it was already installed
pub fn build(args BuildArgs) ! {
	// make sure we install base on the node
	if osal.platform() != .ubuntu {
		return error('only support ubuntu for now')
	}
	rust.install()!

	// install s3cas if it was already done will return true
	console.print_header('build s3cas')

	osal.package_install('libssl-dev,pkg-config')!

	mut gs := gittools.get()!
	mut repo := gs.get_repo(
		url: 'https://github.com/leesmet/s3-cas',
		reset: false,
		pull: true
	)!

	mut path := repo.get_path()!

	cmd := '
	set -ex
	cd ${path}
	cargo build --all-features
	'
	osal.execute_stdout(cmd) or { return error('Cannot install s3.\n${err}') }

	osal.cmd_add(
		// cmdname: ''
		source: '${path}/target/debug/s3-cas'
	)!
}
