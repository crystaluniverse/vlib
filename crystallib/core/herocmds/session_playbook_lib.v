module herocmds

import freeflowuniverse.crystallib.core.base
import freeflowuniverse.crystallib.core.playcmds
import freeflowuniverse.crystallib.core.playbook
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.develop.vscode
import freeflowuniverse.crystallib.develop.sourcetree
import cli { Command, Flag }
import os

pub fn cmd_run_add_flags(mut cmd_run Command) {
	cmd_run.add_flag(Flag{
		flag: .string
		required: false
		name: 'path'
		abbrev: 'p'
		description: 'path where heroscripts can be found.'
	})

	cmd_run.add_flag(Flag{
		flag: .string
		required: false
		name: 'sessionname'
		abbrev: 'sn'
		description: 'name for the session (optional).'
	})
	cmd_run.add_flag(Flag{
		flag: .string
		required: false
		name: 'contextname'
		abbrev: 'cn'
		description: 'name for the context (optional).'
	})
	cmd_run.add_flag(Flag{
		flag: .string
		required: false
		name: 'url'
		abbrev: 'u'
		description: 'url where heroscript can be found.'
	})

	cmd_run.add_flag(Flag{
		flag: .bool
		required: false
		name: 'gitpull'
		abbrev: 'gp'
		description: 'will try to pull.'
	})

	cmd_run.add_flag(Flag{
		flag: .bool
		required: false
		name: 'gitreset'
		abbrev: 'gr'
		description: 'will reset the git repo if there are changes inside, will also pull, CAREFUL.'
	})

	cmd_run.add_flag(Flag{
		flag: .string
		required: false
		name: 'coderoot'
		abbrev: 'cr'
		description: 'Set code root for gittools.'
	})

	cmd_run.add_flag(Flag{
		flag: .bool
		name: 'script'
		abbrev: 's'
		description: 'runs non interactive!'
	})

	cmd_run.add_flag(Flag{
		flag: .bool
		name: 'reset'
		abbrev: 'r'
		description: 'reset, means lose changes of your repos, BE CAREFUL.'
	})

	cmd_run.add_flag(Flag{
		flag: .bool
		required: false
		name: 'edit'
		abbrev: 'e'
		description: 'Open visual studio code for where we found the content.'
	})

	cmd_run.add_flag(Flag{
		flag: .bool
		required: false
		name: 'sourcetree'
		abbrev: 'st'
		description: 'Open sourcetree (git mgmt) for the repo where we found the content.'
	})
}

// returns the session and the path of the fetched repo
fn session_run_get(cmd Command) !(&base.Session, string) {
	mut path := cmd.flags.get_string('path') or { '' }
	mut url := cmd.flags.get_string('url') or { '' }

	mut sessionname := cmd.flags.get_string('sessionname') or { '' }
	mut contextname := cmd.flags.get_string('contextname') or { '' }

	mut coderoot := cmd.flags.get_string('coderoot') or { '' }
	if 'CODEROOT' in os.environ() && coderoot == '' {
		coderoot = os.environ()['CODEROOT']
	}

	if coderoot.len > 0 {
		panic('coderoot >0 not supported yet, not imeplemented.')
	}

	reset := cmd.flags.get_bool('gitreset') or { false }
	pull := cmd.flags.get_bool('gitpull') or { false }
	interactive := !cmd.flags.get_bool('script') or { false }

	mut session := base.session_new(
		session_name: sessionname
		context_name: contextname
		interactive: interactive
	)!

	mut gs := session.context.gitstructure()!
	if url.len > 0 {
		path = gs.code_get(
			pull: pull
			reset: reset
			url: url
			reload: true
		)!
	}

	return session, path
}

// same as session_run_get but will also run the playbook
fn session_run_do(cmd Command) !(&playbook.PlayBook, string) {
	mut session, path := session_run_get(cmd)!

	if path.len == 0 {
		return error(cmd.help_message())
	}

	// add all actions inside to the playbook
	mut plbook := playbook.new(path: path, session: session)!

	playcmds.run(mut plbook)!

	console.print_stdout(plbook.str())
	return &plbook, path
}

// get the repo, check if we need to do
fn session_run_edit_sourcecode(cmd Command) !(&playbook.PlayBook, string) {
	edit := cmd.flags.get_bool('edit') or { false }
	treedo := cmd.flags.get_bool('sourcetree') or { false }

	mut plbook, path := session_run_do(cmd)!

	if path.len == 0 {
		return error('path or url needs to be specified')
	}

	if treedo {
		// mut repo := gittools.git_repo_get(coderoot: coderoot, path: path)!
		// repo.sourcetree()!
		sourcetree.open(path: path)!
	} else if edit {
		vscode.open(path: path)!
	}

	return plbook, path
}
