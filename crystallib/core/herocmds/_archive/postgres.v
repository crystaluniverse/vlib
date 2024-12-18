module herocmds

import freeflowuniverse.crystallib.clients.postgres
import cli { Command, Flag }
import freeflowuniverse.crystallib.ui.console

pub fn cmd_postgres(mut cmdroot Command) {
	mut cmd_run := Command{
		name:          'postgres'
		description:   'manage postgresql'
		required_args: 0
		execute:       postgres_help
	}

	mut cmd_exec := Command{
		required_args: 1
		name:          'exec'
		execute:       cmd_postgres_execute
		description:   'execute the following query'
	}

	mut cmd_check := Command{
		name:        'check'
		execute:     cmd_postgres_check
		description: 'check the postgresql connection'
	}

	mut cmd_configure := Command{
		name:        'configure'
		execute:     cmd_postgres_configure
		description: 'Configure a postgresl connection.'
	}

	mut cmd_print := Command{
		name:        'print'
		execute:     cmd_postgres_print
		description: 'Print configure info.'
	}

	cmd_print.add_flag(Flag{
		flag:        .string
		name:        'name'
		abbrev:      'n'
		description: 'name of the postgresql connection!'
	})

	mut cmd_backupall := Command{
		name:        'backup'
		execute:     cmd_postgres_backupall
		description: 'backup all databases'
	}
	cmd_backupall.add_flag(Flag{
		flag:        .string
		name:        'dest'
		abbrev:      'd'
		description: 'path where backups will be done'
	})
	cmd_backupall.add_flag(Flag{
		flag:        .string
		name:        'name'
		abbrev:      'n'
		description: 'name of the postgresql db!'
	})

	mut cmd_list := Command{
		name:        'list'
		execute:     cmd_postgres_list
		description: 'list databases'
	}

	mut allcmdsref_gen := [&cmd_exec, &cmd_check, &cmd_configure]

	for mut c in allcmdsref_gen {
		c.add_flag(Flag{
			flag:        .string
			name:        'name'
			abbrev:      'n'
			description: 'name of the postgresql connection!'
		})
		cmd_run.add_command(*c)
	}
	cmd_run.add_command(cmd_backupall)
	cmd_run.add_command(cmd_print)
	cmd_run.add_command(cmd_list)
	cmdroot.add_command(cmd_run)

	// console.print_debug(cmdroot.help_message())
}

fn cmd_postgres_execute(cmd Command) ! {
	mut name := cmd.flags.get_string('name') or { 'default' }
	mut cl := postgres.get(instance: name)!
	rows := cl.exec(cmd.args[0])!
	for row in rows {
		console.print_debug(row)
	}
}

fn cmd_postgres_list(cmd Command) ! {
	mut cl := postgres.get(instance: 'default')!
	console.print_debug('## Postgresql Connections:\n')
	items := cl.db_names()!
	for item in items {
		console.print_header(' ${item}')
	}
}

fn cmd_postgres_check(cmd Command) ! {
	mut name := cmd.flags.get_string('name') or { 'default' }
	mut cl := postgres.get(instance: name)!
	cl.check()!
	console.print_debug('DB is answering.')
}

fn cmd_postgres_backupall(cmd Command) ! {
	mut name := cmd.flags.get_string('name') or { '' }
	mut dest := cmd.flags.get_string('dest') or { '' }
	if dest == '' {
		return error("can't find dest:${dest}")
	}
	console.print_debug(" backup db name:'${name}' dest:'${dest}")
	mut cl := postgres.get(instance: name)!
	cl.backup(dest: dest, dbname: name)!
}

fn cmd_postgres_configure(cmd Command) ! {
	mut instance := cmd.flags.get_string('name') or { 'default' }
	if instance == '' {
		instance = 'default'
	}
	mut cnfg := postgres.configurator(instance)!
	mut args := cnfg.get()!
	postgres.configure_interactive(mut args, mut cnfg.session)!
}

fn cmd_postgres_print(cmd Command) ! {
	mut name := cmd.flags.get_string('name') or { 'default' }
	panic('implement')
	// postgres.configprint(name: name)!
}

fn postgres_help(cmd Command) ! {
	console.print_debug(cmd.help_message())
}
