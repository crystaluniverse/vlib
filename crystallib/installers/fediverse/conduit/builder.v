module conduit

import freeflowuniverse.crystallib.installers.base
import freeflowuniverse.crystallib.installers.lang.rust
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.develop.gittools
import freeflowuniverse.crystallib.installers.db.postgresql
import freeflowuniverse.crystallib.ui.console

const url = 'https://github.com/matrix-org/conduit'

@[params]
pub struct BuildArgs {
pub mut:
	reset bool
}

// install conduit will return true if it was already installed
pub fn build(args BuildArgs) ! {
	// make sure we install base on the node
	if osal.platform() != .ubuntu {
		return error('only support ubuntu for now')
	}
	rust.install()!

	// install conduit if it was already done will return true
	console.print_header('build conduit')

	mut gs := gittools.new(coderoot: '/tmp/builder')!
	mut repo := gs.get_repo(
		url: conduit.url
		reset: true
		pull: true
	)!
	gitpath := repo.get_path()!

	cmd := '
	source ${osal.profile_path()} //source the go path
	cd ${gitpath}
	go build -o bin/ ./cmd/...
	'
	osal.execute_stdout(cmd)!
}
