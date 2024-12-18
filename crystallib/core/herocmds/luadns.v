module herocmds

import cli { Command, Flag }
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.develop.luadns

// Main function to set up CLI commands
pub fn cmd_luadns(mut cmdroot Command) {
	mut cmd_luadns := Command{
		name:          'luadns'
		usage:         '
## Manage your LuaDNS

example:

hero luadns load -u https://github.com/example/dns-repo
hero luadns set-domain -d example.com -i 51.129.54.234

        '
		description:   'Manage LuaDNS configurations'
		required_args: 0
		execute:       cmd_luadns_execute
	}

	cmd_luadns.add_command(cmd_luadns_set_domain())
	cmdroot.add_command(cmd_luadns)
}

fn cmd_luadns_set_domain() Command {
	mut cmd := Command{
		name:          'set-domain'
		usage:         'Set a domain in the DNS configurations'
		required_args: 0
		execute:       cmd_luadns_set_domain_execute
	}

	cmd.add_flag(Flag{
		flag:        .string
		required:    true
		name:        'domain'
		abbrev:      'd'
		description: 'Domain to set in the DNS configurations'
	})

	cmd.add_flag(Flag{
		flag:        .string
		required:    true
		name:        'ip'
		abbrev:      'i'
		description: 'IP address for the domain'
	})

	return cmd
}

fn cmd_luadns_execute(cmd Command) ! {
	console.print_stdout(cmd.help_message())
}

fn cmd_luadns_set_domain_execute(cmd Command) ! {
	url := cmd.flags.get_string('url') or {
		console.print_debug('URL flag is required')
		cmd_luadns_help(cmd)
		exit(1)
	}

	domain := cmd.flags.get_string('domain') or {
		console.print_debug('Domain flag is required')
		cmd_luadns_help(cmd)
		exit(1)
	}

	ip := cmd.flags.get_string('ip') or {
		console.print_debug('IP flag is required')
		cmd_luadns_help(cmd)
		exit(1)
	}

	mut lua_dns := luadns.load(url)!
	lua_dns.set_domain(domain, ip) or {
		eprintln('Failed to set domain: ${err}')
		exit(1)
	}
}

fn cmd_luadns_help(cmd Command) {
	console.clear()
	console.print_header('Instructions for LuaDNS:')
	console.print_lf(1)
	console.print_stdout(cmd.help_message())
	console.print_lf(5)
}
