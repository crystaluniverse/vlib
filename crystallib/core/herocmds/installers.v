module herocmds

import freeflowuniverse.crystallib.installers
import cli { Command, Flag }
import freeflowuniverse.crystallib.ui.console

pub fn cmd_installers(mut cmdroot Command) {
	mut cmd_run := Command{
		name:          'installers'
		description:   'a set of installers'
		required_args: 0
		execute:       cmd_installers_execute
	}

	cmd_run.add_flag(Flag{
		flag:        .string
		required:    false
		name:        'names'
		abbrev:      'n'
		description: 'Comma separated list of installers to call.'
	})
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
		name:        'uninstall'
		abbrev:      'u'
		description: 'will uninstall in stead of install.'
	})

	cmd_run.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'gitpull'
		abbrev:      'gp'
		description: 'e.g. in crystallib or other git repo pull changes.'
	})

	cmd_run.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'gitreset'
		abbrev:      'gr'
		description: 'e.g. in crystallib or other git repo pull & reset changes.'
	})
	cmdroot.add_command(cmd_run)
}

fn cmd_installers_execute(cmd Command) ! {
	mut reset := cmd.flags.get_bool('reset') or { false }
	mut uninstall := cmd.flags.get_bool('uninstall') or { false }
	mut gitpull := cmd.flags.get_bool('gitpull') or { false }
	mut gitreset := cmd.flags.get_bool('gitreset') or { false }
	mut names := cmd.flags.get_string('names') or { '' }

	if names == '' {
		console.clear()
		console.print_header('the following installers are known:')
		console.print_lf(2)
		for x in installers.names() {
			console.print_item(x)
		}
		console.print_lf(1)
		console.print_stdout(cmd.help_message())
		console.print_lf(5)
		exit(1)
	}

	installers.install_multi(
		reset:     reset
		names:     names
		uninstall: uninstall
		gitpull:   gitpull
		gitreset:  gitreset
	)!
}
