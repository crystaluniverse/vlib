module herocmds

import freeflowuniverse.crystallib.clients.mail
import freeflowuniverse.crystallib.ui
import freeflowuniverse.crystallib.builder
import freeflowuniverse.crystallib.data.dbfs
import freeflowuniverse.crystallib.core.texttools
import cli { Command, Flag }
import os
import json
import freeflowuniverse.crystallib.ui.console

pub fn cmd_configure(mut cmdroot Command) {
	mut cmd_run := Command{
		name: 'configure'
		description: 'configure parameters for hero environment.'
		required_args: 0
		execute: cmd_configure_execute
	}

	cmd_run.add_flag(Flag{
		flag: .string
		required: false
		name: 'category'
		abbrev: 'c'
		description: 'name of the configure item e.g. mail, postgres.'
	})
	cmd_run.add_flag(Flag{
		flag: .string
		required: false
		name: 'instance'
		abbrev: 'i'
		description: 'instance name'
	})
	cmd_run.add_flag(Flag{
		flag: .bool
		required: false
		name: 'reset'
		abbrev: 'r'
		description: 'will reset.'
	})
	cmd_run.add_flag(Flag{
		flag: .bool
		required: false
		name: 'show'
		abbrev: 's'
		description: 'will show the command.'
	})
	cmd_run.add_flag(Flag{
		flag: .bool
		required: false
		name: 'test'
		abbrev: 't'
		description: 'do a test.'
	})
	cmd_run.add_flag(Flag{
		flag: .string
		required: false
		name: 'push'
		abbrev: 'p'
		description: 'push this config to a destination over ssh e.g. root@212.3.247.26'
	})

	cmdroot.add_command(cmd_run)
}

fn cmd_configure_execute(cmd Command) ! {
	mut reset := cmd.flags.get_bool('reset') or { false }
	mut show := cmd.flags.get_bool('show') or { false }
	mut test := cmd.flags.get_bool('test') or { false }
	mut category := cmd.flags.get_string('category') or { panic('bug') }
	mut instance := cmd.flags.get_string('instance') or { 'default' }
	mut push := cmd.flags.get_string('push') or { '' }
	if instance == '' {
		instance = 'default'
	}
	category = texttools.name_fix(category)
	instance = texttools.name_fix(instance)
	if instance.len == 0 || category.len == 0 {
		return error(cmd.help_message())
	}
	if category == 'mail' {
		mut cnfg := mail.configurator(instance)!
		mut args := cnfg.get()!
		if show {
			cl := mail.get(instance: instance)!
			console.print_debug(cl)
		} else if test {
			mut cl := mail.get(instance: instance)!
			// console.print_debug(cl)
			mut myui := ui.new()!
			to := myui.ask_question(
				question: 'send test mail to'
			)!
			cl.send(to: to, subject: 'this is test mail', body: 'this is example mail.')!
		} else if push == '' {
			mail.configure_interactive(mut args, mut cnfg.session)!
		}
	} else {
		panic('implement')
		// mut kvs := dbfs.new(name: 'config')!
		// key := '${category}_config_${instance}'
		// data := kvs.get(key) or { return error('cannot find object with key: ${key}') }
		// console.print_debug(data)
	}
	if push.len > 0 {
		console.print_header(" will push config: ${instance} to '${push}'")
		path := '${os.home_dir()}/hero/db/config/${category}_config_${instance}'
		path_dest := '~/hero/db/config/${category}_config_${instance}'
		if !os.exists(path) {
			return error('cannot find the source config on: ${path}')
		}
		mut myui := ui.new()!
		ok := myui.ask_yesno(question: 'are you sure?')!
		if ok {
			mut b := builder.new()!
			mut n := b.node_new(ipaddr: push)!
			n.upload(source: path, dest: path_dest, delete: true)!
		}
	}
}
