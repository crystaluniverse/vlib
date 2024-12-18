module herocmds

import freeflowuniverse.crystallib.core.base
import freeflowuniverse.crystallib.web.zola
import cli { Command, Flag }

// path string //if location on filessytem, if exists, this has prio on git_url
// git_url   string // location of where the hero scripts are
// git_pull     bool // means when getting new repo will pull even when repo is already there
// git_pullreset bool // means we will force a pull and reset old content
// coderoot string //the location of coderoot if its another one
pub fn cmd_zola(mut cmdroot Command) {
	mut cmd_zola := Command{
		name:          'zola'
		description:   '
## Manage your ZolaSites

example:

hero run -u https://git.ourworld.tf/threefold_coop/info_asimov/src/branch/main/heroscript -r

The -r will run it, can also do -e or -st to see sourcetree

		
		'
		required_args: 0
		usage:         ''
		execute:       cmd_zola_execute
	}

	cmd_run_add_flags(mut cmd_zola)

	cmd_zola.add_flag(Flag{
		flag:        .string
		name:        'name'
		abbrev:      'n'
		description: 'name of the zola.'
	})

	cmdroot.add_command(cmd_zola)
}

fn cmd_zola_execute(cmd Command) ! {
	mut session, path := plbook_run(cmd)!

	mut name := cmd.flags.get_string('name') or { '' }
	reset := cmd.flags.get_bool('gitreset') or { false }

	// if cmd.name == 'edit' {
	// 	mut book2 := zola.new_from_config(instance: name, reset: reset, context: &session.context)!
	// 	book2.edit()!
	// } else if cmd.name == 'open' {
	// 	mut book2 := zola.new_from_config(instance: name, reset: reset, context: &session.context)!
	// 	book2.generate()!
	// 	book2.open()!
	// } else if cmd.name == 'run' {
	// 	mut book2 := zola.new_from_config(instance: name, reset: reset, context: &session.context)!
	// 	book2.generate()!
	// 	book2.open()!
	// } else {
	// 	return error(cmd.help_message())
	// }
}
