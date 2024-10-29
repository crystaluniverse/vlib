module zdb

import freeflowuniverse.crystallib.develop.gittools
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.installers.base
import freeflowuniverse.crystallib.ui.console

// install zdb will return true if it was already installed
pub fn build() ! {
	base.install()!
	console.print_header('package_install install zdb')
	if !osal.done_exists('install_zdb') && !osal.cmd_exists('zdb') {
		mut gs := gittools.new()!
		mut repo := gs.get_repo(
			url: 'git@github.com:threefoldtech/0-db.git'
			reset: false
			pull: true
		)!
		path := repo.get_path()!
		cmd := '
		set -ex
		cd ${path}
		make
		sudo rsync -rav ${path}/bin/zdb* /usr/local/bin/
		'
		osal.execute_silent(cmd) or { return error('Cannot install zdb.\n${err}') }
		osal.done_set('install_zdb', 'OK')!
	}
}
