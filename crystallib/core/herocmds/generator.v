module herocmds

import freeflowuniverse.crystallib.core.generator.generic
import freeflowuniverse.crystallib.ui.console
import os
import cli { Command, Flag }

pub fn cmd_generator(mut cmdroot Command) {
	mut cmd_run := Command{
		name:          'generate'
		description:   'generator for vlang code in hero context.'
		required_args: 0
		execute:       cmd_generator_execute
	}

	cmd_run.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'reset'
		abbrev:      'r'
		description: 'will reset.'
	})

	cmd_run.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'path'
		abbrev:      'p'
		description: 'path where to generate the code or scan over multiple directories.'
	})

	cmd_run.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'force'
		abbrev:      'f'
		description: 'will work non interactive if possible.'
	})

	cmd_run.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'scan'
		abbrev:      's'
		description: 'force scanning operation.'
	})

	cmd_run.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'installer'
		abbrev:      'i'
		description: 'Make sure its installer.'
	})

	cmdroot.add_command(cmd_run)
}

fn cmd_generator_execute(cmd Command) ! {
	mut force := cmd.flags.get_bool('force') or { false }
	mut reset := cmd.flags.get_bool('reset') or { false }
	mut scan := cmd.flags.get_bool('scan') or { false }
	mut installer := cmd.flags.get_bool('installer') or { false }
	mut path := cmd.flags.get_string('path') or { '' }

	if path == '' {
		path = os.getwd()
	}

	path = path.replace('~', os.home_dir())

	mut cat := generic.Cat.client
	if installer {
		cat = generic.Cat.installer
	}

	if scan {
		generic.scan(path: path, reset: reset, force: force, cat: cat)!
	} else {
		generic.generate(path: path, reset: reset, force: force, cat: cat)!
	}
}
