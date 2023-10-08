module main

import os
import cli { Command }
import baobab.hero.executor.mycmds

fn do() ! {
	mut cmd := Command{
		name: 'hero'
		description: 'Your HERO for our Crystal Lib Tools.'
		version: '1.0.0'
		disable_man: true
	}

	mycmds.cmd_run_config(mut cmd)
	mycmds.cmd_git_config(mut cmd)
	mycmds.cmd_git_actions(mut cmd)

	cmd.setup()
	cmd.parse(os.args)
}

fn main() {
	do() or { panic(err) }
}
