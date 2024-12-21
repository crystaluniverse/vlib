module publishing

import freeflowuniverse.crystallib.core.pathlib
import cli { Command, Flag }
import os
import freeflowuniverse.crystallib.ui.console

pub fn cmd_example_actor() Command {
	mut cmd := Command{
		name: 'example_actor'
		usage: ''
		description: 'create, edit, show mdbooks'
		required_args: 0
		execute: cmd_example_actor_execute
	}

	mut cmd_list := Command{
		sort_flags: true
		name: 'list_books'
		execute: cmd_publisher_list_books
		description: 'will list existing mdbooks'
		pre_execute: pre_func
	}

	mut cmd_open := Command{
		name: 'open'
		execute: cmd_publisher_open
		description: 'will open the publication with the provided name'
		pre_execute: pre_func
	}

	cmd_open.add_flag(Flag{
		flag: .string
		name: 'name'
		abbrev: 'n'
		description: 'name of the publication.'
	})

	cmd.add_command(cmd_list)
	cmd.add_command(cmd_open)
	return cmd
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

fn cmd_execute(cmd Command) ! {
	mut name := cmd.flags.get_string('name') or { '' }

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

fn publisher_help(cmd Command) {
	console.clear()
	console.print_header('Instructions for example actor:')
	console.print_lf(1)
	console.print_stdout(cmd.help_message())
	console.print_lf(5)
}