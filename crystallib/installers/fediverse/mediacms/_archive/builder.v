module mediacms

import freeflowuniverse.crystallib.installers.base
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.develop.gittools
import freeflowuniverse.crystallib.installers
import freeflowuniverse.crystallib.ui.console

@[params]
pub struct BuildArgs {
pub mut:
	reset bool
}

// install mediacms will return true if it was already installed
pub fn build(args BuildArgs) ! {
	// make sure we install base on the node
	if osal.platform() != .ubuntu {
		return error('only support ubuntu for now')
	}

	// install mediacms if it was already done will return true
	console.print_header('build mediacms')

	// mut gs := gittools.get(coderoot: '/tmp/builder')!
	// mut repo := gs.get_repo(
	// 	url: mediacms.url
	// 	reset: true
	// 	pull: true
	// )!
	// gitpath := repo.get_path()!
	// cmd := '
	// source ${osal.profile_path()} //source the go path
	// cd ${gitpath}
	// go build -o bin/ ./cmd/...

	// cp /tmp/builder/github/matrix-org/mediacms/bin/mediacms /usr/local/bin/mediacms
	// cp /tmp/builder/github/matrix-org/mediacms/bin/generate-keys /usr/local/bin/mediacms-generate-keys
	// cp /tmp/builder/github/matrix-org/mediacms/bin/create-account /usr/local/bin/mediacms-create-account
	// cp /tmp/builder/github/matrix-org/mediacms/bin/furl /usr/local/bin/furl

	// '
	// osal.execute_stdout(cmd)!
}
