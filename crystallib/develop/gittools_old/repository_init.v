module gittools

import freeflowuniverse.crystallib.osal.sshagent
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.osal

// this will clone the repo if it doesn't exist yet
fn (mut repo GitRepo) load_from_url() ! {
	// first check if path does not exist yet, if not need to clone
	if !(repo.path.exists()) {
		url := repo.addr.url_http_with_branch_get()
		// console.print_header(' check repo:$url, pull:$args.pull, reset:$args.reset')
		// console.print_debug(repo.addr)
		// need to get the status of the repo
		// console.print_header(' repo $repo.name() check')
		mut needs_to_be_ssh := false

		// check if there is a custom key to be used (sshkey)
		// needs_to_be_ssh0 := repo.ssh_key_load()!
		// if needs_to_be_ssh0 {
		// 	needs_to_be_ssh = true
		// }

		console.print_header(' missing repo, pull: ${url} -> ${repo.path.path}')
		if !needs_to_be_ssh && sshagent.loaded() {
			needs_to_be_ssh = true
		}
		// get the url (http or ssh)
		mut cmd := ''
		if needs_to_be_ssh {
			// console.print_debug("GIT: PULL USING SSH")
			// cmd based on ssh
			cmd = repo.get_clone_cmd(false)
		} else {
			// cmd based on http
			// console.print_debug("GIT: PULL USING HTTP")
			cmd = repo.get_clone_cmd(true)
		}
		osal.exec(cmd: cmd, debug: false) or {
			console.print_stderr('GIT FAILED: ${cmd}')
			return error('Cannot pull repo: ${repo.addr.path()!}. Error was ${err}')
		}
		repo.load()!
	}
}

// path needs to exit, load all from disk
fn (mut repo GitRepo) load_from_path() ! {
	// $if debug {
	// 	console.print_debug('load from path: ${repo.path.path}')
	// }
	repo.status()!
}

fn (repo GitRepo) get_clone_cmd(http bool) string {
	url := repo.url_get(http)
	mut cmd := ''

	mut light := ''
	if repo.gs.config.light {
		light = ' --depth 1 --no-single-branch'
	}

	mut path := repo.addr.path_account()
	// QUESTION: why was branch name used for repo?
	// cmd = 'cd ${path.path} && git clone ${light} ${url} ${repo.addr.branch}'
	cmd = 'cd ${path.path} && git clone ${light} ${url} ${repo.addr.name}'
	if repo.addr.branch != '' {
		cmd += ' -b ${repo.addr.branch}'
	}
	return cmd
}
