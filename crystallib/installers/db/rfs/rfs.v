module rfs

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.installers.lang.rust
import freeflowuniverse.crystallib.develop.gittools
import freeflowuniverse.crystallib.installers.zinit
import freeflowuniverse.crystallib.ui.console

pub fn install() ! {
	rust.install()!
	zinit.install()!
	console.print_header('install rfs')
	if !osal.done_exists('install_rfs') || !osal.cmd_exists('rfs') {
		osal.package_install('musl-dev,musl-tools')!

		mut gs := gittools.new()!
		mut repo := gs.get_repo(url: 'https://github.com/threefoldtech/rfs', reset: true)! 
		path := repo.get_path()!
		cmd := '
		cd ${path}
		rustup target add x86_64-unknown-linux-musl
		cargo build --features build-binary --release --target=x86_64-unknown-linux-musl

		cp ~/code/github/threefoldtech/rfs/target/x86_64-unknown-linux-musl/release/rfs /usr/local/bin/
		'
		console.print_header('build rfs')
		osal.execute_stdout(cmd)!
		osal.done_set('install_rfs', 'OK')!
	}
	console.print_header('rfs already done')
}
