module herocmds

import freeflowuniverse.crystallib.develop.gittools
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

	// cmd_run.add_flag(Flag{
	// 	flag: .string
	// 	required: false
	// 	name: 'sessionname'
	// 	abbrev: 'sn'
	// 	description: 'name for the session (optional).'
	// })
	// cmd_run.add_flag(Flag{
	// 	flag: .string
	// 	required: false
	// 	name: 'contextname'
	// 	abbrev: 'cn'
	// 	description: 'name for the context (optional).'
	// })
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

	cmd_run.add_flag(Flag{
		flag: .bool
		required: false
		name: 'dagu'
		abbrev: 'da'
		description: 'Schedule the heroscripts through DAGU.'
	})
}

// returns the path of the fetched repo
pub fn plbook_code_get(cmd Command) !string {
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

		path = repo.get_path()!
	}

	return path
}

// same as session_run_get but will also run the playbook
fn plbook_run(cmd Command) !(&playbook.PlayBook, string) {
	path := plbook_code_get(cmd)!

	if path.len == 0 {
		return error(cmd.help_message())
	}

	// add all actions inside to the playbook
	mut plbook := playbook.new(path: path)!

	dagu := cmd.flags.get_bool('dagu') or { false }

	playcmds.run(mut plbook, dagu)!

	console.print_stdout(plbook.str())
	return &plbook, path
}

fn plbook_edit_sourcetree(cmd Command) !(&playbook.PlayBook, string) {
	edit := cmd.flags.get_bool('edit') or { false }
	treedo := cmd.flags.get_bool('sourcetree') or { false }

	mut plbook, path := plbook_run(cmd)!

	if path.len == 0 {
		return error('path or url needs to be specified')
	}

	if treedo {
		// mut repo := gittools.git_repo_get(coderoot: coderoot, path: path)!
		// repo.sourcetree()!
		sourcetree.open(path: path)!
	} else if edit {
		mut vscode_ := vscode.new(path)
		vscode_.open()!
	}

	return plbook, path
}
