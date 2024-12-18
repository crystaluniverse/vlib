module main

import os
import cli { Command }
import freeflowuniverse.crystallib.baobab.hero.herocmds

const external_tools = ['build-examples.v']

fn do() ! {
	mut cmd := Command{
		name:        'crystallib'
		description: 'Crystallib CLI'
		version:     '1.0.0'
		disable_man: true
	}

	cmd_build_examples(mut cmd)
	herocmds.cmd_git_do(mut cmd)
	cmd.setup()
	cmd.parse(os.args)
}

fn main() {
	do() or { panic(err) }
}

pub fn cmd_build_examples(mut cmdroot Command) {
	mut cmd_run := Command{
		name:          'build_examples'
		description:   'Build the examples in crystallib.'
		usage:         ''
		required_args: 0
		execute:       cmd_build_examples_execute
	}
	cmdroot.add_command(cmd_run)
}

fn cmd_build_examples_execute(cmd Command) ! {
	file_dir := os.dir(@FILE)
	// os.execute('v -enable-globals ${file_dir}/build-examples.v')
	// command := 'v run ${file_dir}/build_examples.v'
	// os.chdir('${os.dir(file_dir)}')!

	os.execvp('${file_dir}/build-examples.sh', []) or { panic(err) }
}
