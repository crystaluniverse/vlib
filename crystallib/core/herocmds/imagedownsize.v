module herocmds

import freeflowuniverse.crystallib.conversiontools.imagemagick
import cli { Command, Flag }
import os
import freeflowuniverse.crystallib.ui.console

// const wikipath = os.dir(@FILE) + '/wiki'

pub fn cmd_imagedownsize(mut cmdroot Command) {
	mut cmd_run := Command{
		name:          'image_downsize'
		description:   'walk over current director or specified one and downsize all images'
		required_args: 0
		execute:       cmd_imagedownsize_execute
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
		name:        'backupdir'
		abbrev:      'b'
		description: 'What is the backup dir if any.'
	})

	cmd_run.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'convertpng'
		description: 'will convert png to jpg.'
	})

	cmd_run.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'redo'
		abbrev:      'r'
		description: 'will do the checks again.'
	})

	cmdroot.add_command(cmd_run)
}

fn cmd_imagedownsize_execute(cmd Command) ! {
	mut backupdir := cmd.flags.get_string('backupdir') or { '' }
	mut path := cmd.flags.get_string('path') or { '' }
	if path == '' {
		path = os.getwd()
	}
	imagemagick.downsize(
		path:       path
		backupdir:  backupdir
		redo:       cmd.flags.get_bool('redo') or { false }
		convertpng: cmd.flags.get_bool('convertpng') or { false }
	) or {
		print_backtrace()
		console.print_stderr(err.str())
		panic(err)
	}
}
