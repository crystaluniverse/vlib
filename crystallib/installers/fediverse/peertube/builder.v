module peertube

import freeflowuniverse.crystallib.installers.base
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.develop.gittools
import freeflowuniverse.crystallib.installers
import freeflowuniverse.crystallib.installers.docker
import freeflowuniverse.crystallib.ui.console

@[params]
pub struct BuildArgs {
pub mut:
	reset bool
}

// install peertube will return true if it was already installed
pub fn build(args BuildArgs) ! {
	checkplatform()!

	base.install()!

	docker.install()!

	// install peertube if it was already done will return true
	console.print_header('build peertube')

	mut gs := gittools.get()!
	mut repo := gs.get_repo(
		url: 'https://github.com/Chocobozzz/PeerTube.git'
		pull: true
		reset: true
	)!
	dest := repo.get_path()!

	// cmd := '
	// source ${osal.profile_path()} //source the go path
	// cd ${gitpath}

	// '
	// osal.execute_stdout(cmd)!
}
