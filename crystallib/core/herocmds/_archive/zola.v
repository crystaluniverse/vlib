module herocmds

import freeflowuniverse.crystallib.installers.web.zola as zola_installer
import freeflowuniverse.crystallib.web.zola
import cli { Command, Flag }
import os

pub fn cmd_zola(mut cmdroot Command) {
	mut zola_cmd := Command{
		name: 'zola'
		description: 'a fantastic web builder'
		required_args: 0
		execute: cmd_zola_execute
	}

	mut zola_run_cmd := Command{
		sort_flags: true
		name: 'run'
		execute: cmd_zola_execute
		description: ''
	}

	zola_run_cmd.add_flag(Flag{
		flag: .bool
		required: false
		name: 'reset'
		abbrev: 'r'
		description: 'will reset.'
	})

	zola_run_cmd.add_flag(Flag{
		flag: .bool
		required: false
		name: 'serve'
		abbrev: 's'
		description: 'serve the content over webserver.'
	})

	zola_run_cmd.add_flag(Flag{
		flag: .string
		required: false
		name: 'path'
		abbrev: 'p'
		description: 'If not specified will try currentdir/content, is where the source info is.'
	})

	zola_run_cmd.add_flag(Flag{
		flag: .string
		required: false
		name: 'dest'
		abbrev: 'd'
		description: 'If not specified will be currentdir/public.'
	})

	zola_run_cmd.add_flag(Flag{
		flag: .string
		required: false
		name: 'name'
		abbrev: 'n'
		description: 'Name of the website.'
	})

	zola_cmd.add_command(zola_run_cmd)

	cmdroot.add_command(zola_cmd)
}

fn cmd_zola_execute(cmd Command) ! {
	if cmd.name == 'run' {
		mut reset := cmd.flags.get_bool('reset') or { false }

		zola_installer.install()!

		mut path := cmd.flags.get_string('path') or { '' }
		if path == '' {
			path = os.getwd()
		}
		if !os.exists('${path}/content') {
			return error("can't find path for content for the website, tried: ${path}/content")
		}

		mut dest := cmd.flags.get_string('dest') or { '' }
		if dest == '' {
			dest = '${path}/public'
		}

		mut name := cmd.flags.get_string('name') or { 'default' }

		mut serve := cmd.flags.get_bool('serve') or { false }

		mut site := zola.new_site(
			name: name
			url: 'http://localhost:8089'
			path_content: '${path}/content'
			path_build: '/tmp/zola_build_${name}'
			path_publish: dest
		)!

		site.prepare()!
		site.generate()!
		if serve {
			site.serve(
				port: 8089
				open: true
			)!
		}

		return
	} else {
		return error(cmd.help_message())
	}
}
