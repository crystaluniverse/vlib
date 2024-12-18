module publishing

import freeflowuniverse.crystallib.core.pathlib
import cli { Command, Flag }
import os
import freeflowuniverse.crystallib.ui.console

// path string //if location on filessytem, if exists, this has prio on git_url
// git_url   string // location of where the hero scripts are
// git_pull     bool // means when getting new repo will pull even when repo is already there
// git_pullreset bool // means we will force a pull and reset old content
// coderoot string //the location of coderoot if its another one
pub fn cmd_publisher(pre_func fn (Command) !) Command {
	mut cmd_publisher := Command{
		name:          'publisher'
		usage:         '
## Manage your publications

example:

hero publisher -u https://git.ourworld.tf/ourworld_holding/info_ourworld/src/branch/develop/heroscript

If you do -gp it will pull newest book content from git and give error if there are local changes.
If you do -gr it will pull newest book content from git and overwrite local changes (careful).

		'
		description:   'create, edit, show mdbooks'
		required_args: 0
		execute:       cmd_publisher_execute
		pre_execute:   pre_func
	}

	// cmd_run_add_flags(mut cmd_publisher)

	cmd_publisher.add_flag(Flag{
		flag:        .string
		name:        'name'
		abbrev:      'n'
		description: 'name of the publication.'
	})

	cmd_publisher.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'edit'
		description: 'will open vscode for collections & summary.'
	})

	cmd_publisher.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'open'
		abbrev:      'o'
		description: 'will open the generated book.'
	})

	mut cmd_list := Command{
		sort_flags:  true
		name:        'list_books'
		execute:     cmd_publisher_list_books
		description: 'will list existing mdbooks'
		pre_execute: pre_func
	}

	mut cmd_open := Command{
		name:        'open'
		execute:     cmd_publisher_open
		description: 'will open the publication with the provided name'
		pre_execute: pre_func
	}

	cmd_open.add_flag(Flag{
		flag:        .string
		name:        'name'
		abbrev:      'n'
		description: 'name of the publication.'
	})

	cmd_publisher.add_command(cmd_list)
	cmd_publisher.add_command(cmd_open)
	// cmdroot.add_command(cmd_publisher)
	return cmd_publisher
}

fn cmd_publisher_list_books(cmd Command) ! {
	console.print_header('Books:')
	books := publisher.list_books()!
	for book in books {
		console.print_stdout(book.str())
	}
}

fn cmd_publisher_open(cmd Command) ! {
	name := cmd.flags.get_string('name') or { '' }
	publisher.open(name)!
}

fn cmd_publisher_execute(cmd Command) ! {
	mut name := cmd.flags.get_string('name') or { '' }

	// mut url := cmd.flags.get_string('url') or { '' }
	// mut path := cmd.flags.get_string('path') or { '' }
	// if path.len > 0 || url.len > 0 {
	// 	// execute the attached playbook
	// 	mut plbook, _ := herocmds.plbook_run(cmd)!
	// 	play(mut plbook)!
	// 	// get name from the book.generate action
	// 	// if name == '' {
	// 	// 	mut a := plbook.action_get(actor: 'mdbook', name: 'define')!
	// 	// 	name = a.params.get('name') or { '' }
	// 	// }
	// } else {
	// 	publisher_help(cmd)
	// }

	if name == '' {
		console.print_debug('did not find name of book to generate, check in heroscript or specify with --name')
		publisher_help(cmd)
		exit(1)
	}

	edit := cmd.flags.get_bool('edit') or { false }
	open := cmd.flags.get_bool('open') or { false }
	if edit || open {
		// mdbook.book_open(name)!
	}

	if edit {
		// publisher.book_edit(name)!
	}
}

// fn pre_func(cmd Command) ! {
// 	herocmds.plbook_run(cmd)!
// }

fn publisher_help(cmd Command) {
	console.clear()
	console.print_header('Instructions for publisher:')
	console.print_lf(1)
	console.print_stdout(cmd.help_message())
	console.print_lf(5)
}
