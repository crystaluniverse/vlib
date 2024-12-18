module herocmds

import cli { Command, Flag }
import freeflowuniverse.crystallib.ui.console

// path string //if location on filessytem, if exists, this has prio on git_url
// git_url   string // location of where the hero scripts are
// git_pull     bool // means when getting new repo will pull even when repo is already there
// git_pullreset bool // means we will force a pull and reset old content
// coderoot string //the location of coderoot if its another one
pub fn cmd_zola(mut cmdroot Command) {
	mut cmd_zola := Command{
		name:          'zola'
		description:   'cool web publishing tool.'
		usage:         '
## Manage your zolas

example:

hero zola -u https://git.ourworld.tf/tfgrid/info_tfgrid/src/branch/main/heroscript

If you do -gp it will pull newest book content from git and give error if there are local changes.
If you do -gr it will pull newest book content from git and overwrite local changes (careful).

		'
		required_args: 0
		execute:       cmd_zola_execute
	}

	cmd_run_add_flags(mut cmd_zola)

	cmd_zola.add_flag(Flag{
		flag:        .string
		name:        'name'
		abbrev:      'n'
		description: 'name of the zola.'
	})

	// cmd_zola.add_flag(Flag{
	// 	flag: .bool
	// 	required: false
	// 	name: 'edit'
	// 	description: 'will open vscode for collections & summary.'
	// })

	cmd_zola.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'open'
		abbrev:      'o'
		description: 'will open the generated site.'
	})

	cmdroot.add_command(cmd_zola)
}

fn cmd_zola_execute(cmd Command) ! {
	mut name := cmd.flags.get_string('name') or { '' }

	mut url := cmd.flags.get_string('url') or { '' }
	mut path := cmd.flags.get_string('path') or { '' }
	if path.len > 0 || url.len > 0 {
		// execute the attached playbook
		mut plbook, _ := plbook_run(cmd)!

		// get name from the book.generate action
		if name == '' {
			mut a := plbook.action_get(actor: 'zola', name: 'generate')!
			name = a.params.get('name') or { '' }
		}
	} else {
		return error(cmd.help_message())
	}

	if name == '' {
		console.print_debug('did not find name of book to generate, check in heroscript or specify with --name')
		return error(cmd.help_message())
	}

	// edit := cmd.flags.get_bool('edit') or { false }
	// open := cmd.flags.get_bool('open') or { false }
	// if open {
	// 	zola.site_open(name)!
	// }

	// TODO
	// if edit {
	// 	zola.site_edit(name)!
	// }
}
