module herocmds

import freeflowuniverse.crystallib.web.mdbook
import freeflowuniverse.crystallib.core.pathlib
import cli { Command, Flag }
import os
import freeflowuniverse.crystallib.ui.console

// path string //if location on filessytem, if exists, this has prio on git_url
// git_url   string // location of where the hero scripts are
// git_pull     bool // means when getting new repo will pull even when repo is already there
// git_pullreset bool // means we will force a pull and reset old content
// coderoot string //the location of coderoot if its another one
pub fn cmd_mdbook(mut cmdroot Command) {
	mut cmd_mdbook := Command{
		name:          'mdbook'
		usage:         '
## Manage your MDBooks

example:

hero mdbook -u https://git.ourworld.tf/tfgrid/info_tfgrid/src/branch/main/heroscript

If you do -gp it will pull newest book content from git and give error if there are local changes.
If you do -gr it will pull newest book content from git and overwrite local changes (careful).

		'
		description:   'create, edit, show mdbooks'
		required_args: 0
		execute:       cmd_mdbook_execute
	}

	cmd_run_add_flags(mut cmd_mdbook)

	cmd_mdbook.add_flag(Flag{
		flag:        .string
		name:        'name'
		abbrev:      'n'
		description: 'name of the mdbook.'
	})

	// cmd_mdbook.add_flag(Flag{
	// 	flag: .bool
	// 	required: false
	// 	name: 'edit'
	// 	description: 'will open vscode for collections & summary.'
	// })

	cmd_mdbook.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'open'
		abbrev:      'o'
		description: 'will open the generated book.'
	})

	mut cmd_list := Command{
		sort_flags:  true
		name:        'list'
		execute:     cmd_mdbook_list
		description: 'will list existing mdbooks'
	}

	cmd_mdbook.add_command(cmd_list)
	cmdroot.add_command(cmd_mdbook)
}

fn cmd_mdbook_list(cmd Command) ! {
	console.print_header('MDBooks:')
	build_path := os.join_path(os.home_dir(), 'hero/var/mdbuild')
	mut build_dir := pathlib.get_dir(path: build_path)!
	list := build_dir.list(
		recursive: false
		dirs_only: true
	)!
	for path in list.paths {
		console.print_stdout(path.name())
	}
}

fn cmd_mdbook_execute(cmd Command) ! {
	mut name := cmd.flags.get_string('name') or { '' }

	mut url := cmd.flags.get_string('url') or { '' }
	mut path := cmd.flags.get_string('path') or { '' }
	if path.len > 0 || url.len > 0 {
		// execute the attached playbook
		mut plbook, _ := plbook_run(cmd)!
		// get name from the book.generate action
		if name == '' {
			mut a := plbook.action_get(actor: 'mdbook', name: 'define')!
			name = a.params.get('name') or { '' }
		}
	} else {
		mdbook_help(cmd)
	}

	if name == '' {
		console.print_debug('did not find name of book to generate, check in heroscript or specify with --name')
		mdbook_help(cmd)
		exit(1)
	}

	edit := cmd.flags.get_bool('edit') or { false }
	open := cmd.flags.get_bool('open') or { false }
	if edit || open {
		mdbook.book_open(name)!
	}

	if edit {
		mdbook.book_edit(name)!
	}
}

fn mdbook_help(cmd Command) {
	console.clear()
	console.print_header('Instructions for mdbook:')
	console.print_lf(1)
	console.print_stdout(cmd.help_message())
	console.print_lf(5)
}
