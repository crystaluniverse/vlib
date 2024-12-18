module herocmds

import cli { Command }

// path string //if location on filessytem, if exists, this has prio on git_url
// git_url   string // location of where the hero scripts are
// git_pull     bool // means when getting new repo will pull even when repo is already there
// git_pullreset bool // means we will force a pull and reset old content
// coderoot string //the location of coderoot if its another one
pub fn cmd_run(mut cmdroot Command) {
	mut cmd_run := Command{
		name:          'run'
		usage:         '
## Powerfull command to run heroscript

heroscript has numerous ways to execute actions using your hero tool.

example:

hero run -u https://git.ourworld.tf/threefold_coop/info_asimov/src/branch/main/heroscript

Can also do -e or -st to see sourcetree

If you do -gp it will pull newest heroscripts from git and give error if there are local changes.
If you do -gr it will pull newest heroscripts from git and overwrite local changes (careful).


		'
		required_args: 0
		description:   'run heroscript commands'
		execute:       cmd_heroscript_execute
	}
	cmd_run_add_flags(mut cmd_run)

	cmdroot.add_command(cmd_run)
}

fn cmd_heroscript_execute(cmd Command) ! {
	plbook_edit_sourcetree(cmd)!
}
