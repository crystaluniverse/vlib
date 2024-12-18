module base

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.ui.console
import os

const templatespath = os.dir(@FILE) + '/templates'

// install base will return true if it was already installed
pub fn osx_uninstall_containers() ! {
	console.print_header('Uninstall Containers')
	pl := osal.platform()
	if pl != .osx {
		return error('only support OSX')
	}

	containers_uninstall_file := $embed_file('templates/containers_uninstall.sh')
	osal.exec(
		cmd:          containers_uninstall_file.to_string()
		stdout:       false
		ignore_error: false
		shell:        true
	) or { return error('cannot uninstall containers, something went wrong.\n${err}') }

	// will never come here because of shell: true
	console.print_header('Removed brew and docker ...')
}

// pub fn osx_uninstall_brew() ! {
// 	console.print_header('Uninstall Brew')
// 	pl := osal.platform()
// 	if pl != .osx {
// 		return error("only support OSX")
// 	}
// 	return error('cannot uninstall containers, something went wrong.\n${err}')

// 	brew_uninstall_file:=$embed_file('templates/brew_uninstall.sh')
// 	osal.exec(cmd: brew_uninstall_file.to_string(), stdout: true, ignore_error:false, shell: true
// 	) or { return error('cannot uninstall brew, something went wrong.\n${err}') }

// 	//will never come here because of shell: true
// 	console.print_header('Removed brew and docker ...')
// }
