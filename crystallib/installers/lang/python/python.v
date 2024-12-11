module python

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.installers.base
import freeflowuniverse.crystallib.ui.console

pub fn install() ! {
	if !osal.done_exists('install_python') && (!osal.cmd_exists('python') && !osal.cmd_exists('python3')) {
		base.install()!
		console.print_header('package install python')
		osal.package_install('python3')!

		pl := osal.platform()
		if pl == .arch {
			osal.package_install('python-pipx,python-pip,sqlite')!
		} else if pl == .ubuntu {
			osal.package_install('python-pipx,python-pip,sqlite')!
		} else {
			return error('only support arch & ubuntu.')
		}
	}

	// console.print_header('python already done')
}

pub fn check() ! {
	// todo: do a monitoring check to see if it works
	// cmd := '
	// '
	// r := osal.execute_silent(cmd)!
	// console.print_debug(r)
}
