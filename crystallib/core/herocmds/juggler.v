module herocmds

import freeflowuniverse.crystallib.develop.juggler
import freeflowuniverse.crystallib.develop.gittools
import cli { Command, Flag }
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.base
import os

// path string //if location on filessytem, if exists, this has prio on git_url
// git_url   string // location of where the hero scripts are
// git_pull     bool // means when getting new repo will pull even when repo is already there
// git_pullreset bool // means we will force a pull and reset old content
// coderoot string //the location of coderoot if its another one
pub fn cmd_juggler(mut cmdroot Command) {
	mut cmd_juggler := Command{
		name: 'juggler'
		usage: '
## Continuous Integration and Deployment for Hero 

example:

hero juggler -u https://git.ourworld.tf/tfgrid/info_tfgrid/src/branch/main/heroscript

If you do -gp it will pull newest book content from git and give error if there are local changes.
If you do -gr it will pull newest book content from git and overwrite local changes (careful).

		'
		description: 'configure ci/cd for repos'
		required_args: 0
		execute: cmd_juggler_execute
	}

	cmd_run_add_flags(mut cmd_juggler)

	cmd_juggler.add_flag(Flag{
		flag: .int
		required: false
		name: 'port'
		abbrev: ''
		description: 'will open the juggler user interface.'
	})
	cmd_juggler.add_flag(Flag{
		flag: .string
		required: true
		name: 'username'
		abbrev: 'n'
		description: 'username for juggler.'
	})
	cmd_juggler.add_flag(Flag{
		flag: .string
		required: true
		name: 'password'
		abbrev: 'p'
		description: 'password for juggler.'
	})

	cmdroot.add_command(cmd_juggler)
}

fn cmd_juggler_execute(cmd Command) ! {
	mut url := cmd.flags.get_string('url') or { '' }
	mut port := cmd.flags.get_int('port') or { 8000 }
	mut username := cmd.flags.get_string('username') or { 'abc' }
	mut password := cmd.flags.get_string('password') or { 'abc' }
	mut reset := cmd.flags.get_bool('reset') or { false }

	if url.len > 0 {
		mut j := juggler.configure(
			url: url
			username: username
			password: password
			reset: true
		)!
		j.run(8000)!
	} else {
		juggler_help(cmd)
	}
}

fn juggler_help(cmd Command) {
	console.clear()
	console.print_header('Instructions for juggler:')
	console.print_lf(1)
	console.print_stdout(cmd.help_message())
	console.print_lf(5)
}

// returns the path of the fetched repo
fn juggler_code_get(cmd Command) !string {
	mut path := cmd.flags.get_string('path') or { '' }
	mut url := cmd.flags.get_string('url') or { '' }

	// mut sessionname := cmd.flags.get_string('sessionname') or { '' }
	// mut contextname := cmd.flags.get_string('contextname') or { '' }

	mut coderoot := cmd.flags.get_string('coderoot') or { '' }
	if 'CODEROOT' in os.environ() && coderoot == '' {
		coderoot = os.environ()['CODEROOT']
	}

	if coderoot.len > 0 {
		base.context_new(coderoot: coderoot)!
		// panic('coderoot >0 not supported yet, not imeplemented.')
	}

	reset := cmd.flags.get_bool('gitreset') or { false }
	pull := cmd.flags.get_bool('gitpull') or { false }
	// interactive := !cmd.flags.get_bool('script') or { false }

	mut gs := gittools.get(coderoot: coderoot)!
	if url.len > 0 {
		mut repo := gs.get_repo(
			pull: pull
			reset: reset
			url: url
			reload: true
		)!
		return repo.get_path()!
	}

	return path
}
