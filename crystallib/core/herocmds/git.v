module herocmds

import freeflowuniverse.crystallib.develop.gittools
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.ui.console
import cli { Command, Flag }
import os
import crypto.md5

pub fn cmd_git(mut cmdroot Command) {
	mut cmd_run := Command{
		name: 'git'
		description: 'Work with your repos, list, commit, pull, reload, ...'
		// required_args: 1
		usage: 'sub commands of git are '
		execute: cmd_git_execute
		sort_commands: true
	}

	mut clone_command := Command{
		sort_flags: true
		name: 'clone'
		execute: cmd_git_execute
		description: 'will clone the repo based on a given url, e.g. https://github.com/freeflowuniverse/webcomponents/tree/main'
	}

	mut pull_command := Command{
		sort_flags: true
		name: 'pull'
		execute: cmd_git_execute
		description: 'will pull the content, if it exists for each found repo.'
	}

	mut push_command := Command{
		sort_flags: true
		name: 'push'
		execute: cmd_git_execute
		description: 'will push the content, if it exists for each found repo.'
	}

	mut commit_command := Command{
		sort_flags: true
		name: 'commit'
		execute: cmd_git_execute
		description: 'will commit newly found content, specify the message.'
	}

	mut reload_command := Command{
		sort_flags: true
		name: 'reload'
		execute: cmd_git_execute
		description: 'reset the cache of the repos, they are kept for 24h in local redis, this will reload all info.'
	}

	mut delete_command := Command{
		sort_flags: true
		name: 'delete'
		execute: cmd_git_execute
		description: 'delete the repo.'
	}

	mut list_command := Command{
		sort_flags: true
		name: 'list'
		execute: cmd_git_execute
		description: 'list all repos.'
	}

	mut sourcetree_command := Command{
		sort_flags: true
		name: 'sourcetree'
		execute: cmd_git_execute
		description: 'Open sourcetree on found repos, will do for max 5.'
	}

	mut editor_command := Command{
		sort_flags: true
		name: 'edit'
		execute: cmd_git_execute
		description: 'Open visual studio code on found repos, will do for max 5.'
	}

	mut cmd_cd := Command{
		sort_flags: true
		name: 'cd'
		execute: cmd_git_execute
		description: 'cd to a git repo, use e.g. eval $(git cd -u https://github.com/threefoldfoundation/www_threefold_io)'
	}

	cmd_cd.add_flag(Flag{
		flag: .string
		required: false
		name: 'url'
		abbrev: 'u'
		description: 'url for git cd operation, so we know where to cd to'
	})

	mut allcmdsref := [&list_command, &clone_command, &push_command, &pull_command, &commit_command,
		&reload_command, &delete_command, &sourcetree_command, &editor_command]

	for mut c in allcmdsref {
		c.add_flag(Flag{
			flag: .bool
			required: false
			name: 'silent'
			abbrev: 's'
			description: 'be silent.'
		})
	}

	mut allcmdscommit := [&push_command, &pull_command, &commit_command]

	for mut c in allcmdscommit {
		c.add_flag(Flag{
			flag: .string
			required: false
			name: 'message'
			abbrev: 'm'
			description: 'which message to use for commit.'
		})
	}

	mut urlcmds := [&clone_command, &pull_command, &push_command, &editor_command, &sourcetree_command]
	for mut c in urlcmds {
		c.add_flag(Flag{
			flag: .string
			required: false
			name: 'url'
			abbrev: 'u'
			description: 'url for clone operation.'
		})
		c.add_flag(Flag{
			flag: .bool
			required: false
			name: 'reset'
			description: 'force a pull and reset changes.'
		})
		c.add_flag(Flag{
			flag: .bool
			required: false
			name: 'pull'
			description: 'force a pull.'
		})
		c.add_flag(Flag{
			flag: .bool
			required: false
			name: 'pullreset'
			abbrev: 'pr'
			description: 'force a pull and do a reset.'
		})
		c.add_flag(Flag{
			flag: .bool
			required: false
			name: 'recursive'
			description: 'if we do a clone or a pull we also get the git submodules.'
		})
	}

	for mut c in allcmdsref {
		c.add_flag(Flag{
			flag: .string
			required: false
			name: 'filter'
			abbrev: 'f'
			description: 'Filter is part of path of repo e.g. threefoldtech/info_'
		})

		c.add_flag(Flag{
			flag: .string
			required: false
			name: 'repo'
			abbrev: 'r'
			description: 'name of repo'
		})
		c.add_flag(Flag{
			flag: .string
			required: false
			name: 'branch'
			abbrev: 'b'
			description: 'branch of repo (optional)'
		})

		c.add_flag(Flag{
			flag: .string
			required: false
			name: 'account'
			abbrev: 'a'
			description: 'name of account e.g. threefoldtech'
		})

		c.add_flag(Flag{
			flag: .string
			required: false
			name: 'provider'
			abbrev: 'p'
			description: 'name of provider e.g. github'
		})
	}
	for mut c_ in allcmdsref {
		mut c := *c_
		c.add_flag(Flag{
			flag: .string
			required: false
			name: 'coderoot'
			abbrev: 'cr'
			description: 'If you want to use another directory for your code root.'
		})
		c.add_flag(Flag{
			flag: .bool
			required: false
			name: 'script'
			abbrev: 'z'
			description: 'to use in scripts, will not run interative and ask questions.'
		})
		cmd_run.add_command(c)
	}
	cmd_run.add_command(cmd_cd)
	cmdroot.add_command(cmd_run)
}

fn cmd_git_execute(cmd Command) ! {
	mut silent := cmd.flags.get_bool('silent') or { false }
	if silent || cmd.name == 'cd' {
		console.silent_set()
	}
	mut coderoot := cmd.flags.get_string('coderoot') or { '' }

	if 'CODEROOT' in os.environ() && coderoot == '' {
		coderoot = os.environ()['CODEROOT']
	}

	mut gs := gittools.get()!
	if coderoot.len > 0 {
		//is a hack for now 
		gs = gittools.new(coderoot: coderoot)!
	}

	// create the filter for doing group actions, or action on 1 repo
	mut filter := cmd.flags.get_string('filter') or { '' }
	mut branch := cmd.flags.get_string('branch') or { '' }
	mut repo := cmd.flags.get_string('repo') or { '' }
	mut account := cmd.flags.get_string('account') or { '' }
	mut provider := cmd.flags.get_string('provider') or { '' }

	if cmd.name != 'cd' {
		// check if we are in a git repo
		if repo == '' && account == '' && provider == '' && filter == '' {
			if r0 := gs.get_working_repo() {
				repo = r0.name
				account = r0.account
				provider = r0.provider
			}
		}
	}

	if cmd.name in gittools.gitcmds.split(',') {
		mut pull := cmd.flags.get_bool('pull') or { false }
		mut reset := cmd.flags.get_bool('reset') or { false }
		mut recursive := cmd.flags.get_bool('recursive') or { false }
		if cmd.flags.get_bool('pullreset') or { false } {
			pull = true
			reset = true
		}
		mypath := gs.do(
			filter: filter
			repo: repo
			account: account
			provider: provider
			branch: branch
			recursive: recursive
			cmd: cmd.name
			script: cmd.flags.get_bool('script') or { false }
			pull: pull
			reset: reset
			msg: cmd.flags.get_string('message') or { '' }
			url: cmd.flags.get_string('url') or { '' }

		)!
		if cmd.name == 'cd' {
			print('cd ${mypath}\n')
		}
		return
	} else {
		// console.print_debug(" Supported commands are: ${gittools.gitcmds}")
		return error(cmd.help_message())
	}
}
