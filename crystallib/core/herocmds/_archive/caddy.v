module herocmds

import cli { Command }
import freeflowuniverse.crystallib.ui.console

// path string //if location on filessytem, if exists, this has prio on git_url
// git_url   string // location of where the hero scripts are
// git_pull     bool // means when getting new repo will pull even when repo is already there
// git_pullreset bool // means we will force a pull and reset old content
// coderoot string //the location of coderoot if its another one
pub fn cmd_caddy(mut cmdroot Command) {
	mut cmd_caddy := Command{
		name:          'caddy'
		usage:         '
## Manage your Caddy

example:

hero caddy -u https://git.ourworld.tf/tfgrid/info_tfgrid/src/branch/main/heroscript

If you do -gp it will pull newest caddy content from git and give error if there are local changes.
If you do -gr it will pull newest caddy content from git and overwrite local changes (careful).

		'
		description:   'create, caddys'
		required_args: 0
		execute:       cmd_caddy_execute
	}

	// this adds the git command flags to it
	cmd_run_add_flags(mut cmd_caddy)

	cmdroot.add_command(cmd_caddy)
}

fn cmd_caddy_execute(cmd Command) ! {
	mut url := cmd.flags.get_string('url') or { '' }
	mut path := cmd.flags.get_string('path') or { '' }
	if path.len > 0 || url.len > 0 {
		// execute the attached playbook
		mut plbook, _ := plbook_run(cmd)!
		// get name from the caddy.generate action
		mut a := plbook.action_get(actor: 'caddy', name: 'generate')!
	} else {
		caddy_help(cmd)
	}
}

fn caddy_help(cmd Command) {
	console.clear()
	console.print_header('Instructions for caddy:')
	console.print_lf(1)
	console.print_stdout(cmd.help_message())
	console.print_lf(5)
}
