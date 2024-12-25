module repository

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.ui.console
// install repository will return true if it was already installed

pub fn install(repo_url string) ! {
	split_url := repo_url.split('/')
	mut repo_name := split_url[split_url.len - 1].trim_string_right('.git')
	mut repo_owner := split_url[split_url.len - 2]
	// install repository if it was already done will return true
	console.print_header('package_install install repository: ${repo_owner}/${repo_name}')
	if !(i.state == .reset) && osal.done_exists('install_${repo_owner}/${repo_name}') {
		console.print_debug('    package_install ${repo_owner}/${repo_name} was already done')
		return
	}

	// TODO: check if repo exists
	// if cmd_exists('v') {
	// 	console.print_debug('repository was already installed.')
	// 	return
	// }

	osal.execute_silent('mkdir -p code/github/${repo_owner}') or {
		return error('could not create directory code/github:\n${err}')
	}

	cmd := 'git clone ${repo_url} code/github/${repo_owner}/${repo_name}'

	osal.execute_silent(cmd) or {
		return error('Cannot install repository: ${repo_owner}/${repo_name} \n ${err}')
	}

	osal.done_set('install_${repo_owner}/${repo_name}', 'OK')!
	return
}
