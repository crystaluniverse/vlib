module herocmds

import freeflowuniverse.crystallib.core.generator.installer
import freeflowuniverse.crystallib.core.generator.generic
import freeflowuniverse.crystallib.ui.console
import cli { Command, Flag }
import os

pub fn cmd_gen(mut cmdroot Command) {
	mut cmd_run := Command{
		name:        'generate'
		description: 'Generate code, ...'
		// required_args: 1
		usage:         'sub commands of generate are installer (only one for now)'
		execute:       cmd_gen_execute
		sort_commands: true
	}

	mut gen_command := Command{
		sort_flags:  true
		name:        'installer'
		execute:     cmd_gen_execute
		description: 'will generate code for installers, execute in the directory where to generate.'
	}

	mut gen_command_generic := Command{
		sort_flags:  true
		name:        'generic'
		execute:     cmd_gen_execute
		description: 'will generate code for installers, execute in the directory where to generate.'
	}

	mut allcmdsref_gen := [&gen_command, &gen_command_generic]

	for mut c in allcmdsref_gen {
		c.add_flag(Flag{
			flag:        .bool
			name:        'reset'
			abbrev:      'r'
			description: 'do you want to reset all? Dangerous!'
		})
		c.add_flag(Flag{
			flag:        .bool
			name:        'script'
			abbrev:      's'
			description: 'run non interactive!'
		})
		c.add_flag(Flag{
			flag:        .string
			name:        'path'
			abbrev:      'p'
			description: 'path where to generate code!'
		})

		cmd_run.add_command(*c)
	}
	cmdroot.add_command(cmd_run)
}

fn cmd_gen_execute(cmd Command) ! {
	mut reset := cmd.flags.get_bool('reset') or { false }
	mut isscript := cmd.flags.get_bool('script') or { false }
	mut path := cmd.flags.get_string('path') or { '' }

	if !isscript {
		console.clear()
	}

	if cmd.name == 'installer' {
		installer.do(reset: reset, interactive: !isscript, path: path)!
		return
	} else if cmd.name == 'generic' {
		generic.do(reset: reset, interactive: !isscript, path: path)!
		return
	} else {
		return error(cmd.help_message())
	}
}
