module zinit

import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.osal

__global (
	zinit_global_manager []Zinit
)

pub fn new() !Zinit {
	if zinit_global_manager.len == 0 {
		mut z := Zinit{
			path:     pathlib.get_dir(path: '/etc/zinit', create: true)!
			pathcmds: pathlib.get_dir(path: '/etc/zinit/cmds', create: true)!
		}
		zinit_global_manager << z
		z.load()!
	}
	return zinit_global_manager[0]
}

pub fn check() bool {
	if !osal.cmd_exists('zinit') {
		return false
	}
	// println(osal.execute_ok('zinit list'))
	return osal.execute_ok('zinit list')
}

// remove all know services to zinit
pub fn destroy() ! {
	mut zinitpath := pathlib.get_dir(path: '/etc/zinit', create: true)!
	zinitpath.empty()!
	console.print_header(' zinit destroyed')
}
