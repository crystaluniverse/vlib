module herocmds

import freeflowuniverse.crystallib.conversiontools.docsorter
import cli { Command, Flag }
import os
import freeflowuniverse.crystallib.ui.console

// const wikipath = os.dir(@FILE) + '/wiki'

pub fn cmd_docsorter(mut cmdroot Command) {
	mut cmd_run := Command{
		name:          'docsorter'
		description:   'can sort, export, ... pdfs and other docs.'
		required_args: 0
		execute:       cmd_docsorter_execute
	}

	cmd_run.add_flag(Flag{
		flag:        .string
		required:    false
		name:        'path'
		abbrev:      'p'
		description: 'If not in current directory.'
	})

	cmd_run.add_flag(Flag{
		flag:        .string
		required:    false
		name:        'instructions'
		abbrev:      'i'
		description: 'Location to the instructions file, format is text file with per line:\naaa:ourworld:kristof_bio\naab:phoenix:phoenix_digital_nation_litepaper:Litepaper of how a Digital nation can use the Hero Phone'
	})

	cmd_run.add_flag(Flag{
		flag:        .string
		required:    false
		name:        'dest'
		abbrev:      'd'
		description: 'if not given will bet /tmp/export.'
	})

	cmd_run.add_flag(Flag{
		flag:        .bool
		name:        'reset'
		abbrev:      'r'
		description: 'reset the export dir.'
	})

	cmd_run.add_flag(Flag{
		flag:        .bool
		name:        'slides'
		abbrev:      's'
		description: 'extract slides out of the pdfs.'
	})

	cmdroot.add_command(cmd_run)
}

fn cmd_docsorter_execute(cmd Command) ! {
	mut dest := cmd.flags.get_string('dest') or { '' }
	if dest == '' {
		dest = '/tmp/export'
	}
	mut path := cmd.flags.get_string('path') or { '' }
	if path == '' {
		path = os.getwd()
	}
	mut instructions := cmd.flags.get_string('instructions') or { '' }
	mut reset := cmd.flags.get_bool('reset') or { false }
	mut slides := cmd.flags.get_bool('slides') or { false }

	docsorter.sort(
		path:         path
		export_path:  dest
		instructions: instructions
		reset:        reset
		slides:       slides
	) or {
		print_backtrace()
		console.print_stderr(err.str())
		exit(1)
	}
}
