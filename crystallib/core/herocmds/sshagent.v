module herocmds

import freeflowuniverse.crystallib.osal.sshagent
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.ui
import cli { Command, Flag }

pub fn cmd_sshagent(mut cmdroot Command) {
	mut cmd_run := Command{
		name:        'sshagent'
		description: 'Work with SSHAgent'
		// required_args: 1
		usage:         'sub commands of generate are list, generate, unload, load'
		execute:       cmd_sshagent_execute
		sort_commands: true
	}

	mut sshagent_command_list := Command{
		sort_flags:  true
		name:        'list'
		execute:     cmd_sshagent_execute
		description: 'list ssh-keys.'
	}

	mut sshagent_command_generate := Command{
		sort_flags:  true
		name:        'generate'
		execute:     cmd_sshagent_execute
		description: 'generate ssh-key.'
	}

	mut sshagent_command_add := Command{
		sort_flags:  true
		name:        'add'
		execute:     cmd_sshagent_execute
		description: 'add a key starting from private key, only works interactive for nows.'
	}

	sshagent_command_generate.add_flag(Flag{
		flag:        .bool
		name:        'load'
		abbrev:      'l'
		description: 'should key be loaded'
	})

	mut sshagent_command_load := Command{
		sort_flags:  true
		name:        'load'
		execute:     cmd_sshagent_execute
		description: 'load ssh-key in agent.'
	}

	mut sshagent_command_unload := Command{
		sort_flags:  true
		name:        'forget'
		execute:     cmd_sshagent_execute
		description: 'Unload ssh-key from agent.'
	}

	mut sshagent_command_reset := Command{
		sort_flags:  true
		name:        'reset'
		execute:     cmd_sshagent_execute
		description: 'Reset all keys, means unload them all.'
	}

	mut allcmdsref_gen0 := [&sshagent_command_generate, &sshagent_command_load, &sshagent_command_unload,
		&sshagent_command_reset, &sshagent_command_add]
	for mut d in allcmdsref_gen0 {
		d.add_flag(Flag{
			flag:        .string
			name:        'name'
			abbrev:      'n'
			required:    true
			description: 'name of the key'
		})
	}

	mut allcmdsref_gen := [&sshagent_command_list, &sshagent_command_generate, &sshagent_command_load,
		&sshagent_command_unload, &sshagent_command_reset]

	for mut c in allcmdsref_gen {
		// c.add_flag(Flag{
		// 	flag: .bool
		// 	name: 'reset'
		// 	abbrev: 'r'
		// 	description: 'do you want to reset all? Dangerous!'
		// })
		c.add_flag(Flag{
			flag:        .bool
			name:        'script'
			abbrev:      's'
			description: 'runs non interactive!'
		})

		cmd_run.add_command(*c)
	}
	cmdroot.add_command(cmd_run)
}

fn cmd_sshagent_execute(cmd Command) ! {
	// mut reset := cmd.flags.get_bool('reset') or {false }
	mut isscript := cmd.flags.get_bool('script') or { false }
	mut load := cmd.flags.get_bool('load') or { false }
	mut name := cmd.flags.get_string('name') or { '' }

	mut agent := sshagent.new()!

	if cmd.name == 'list' {
		if !isscript {
			console.clear()
		}
		console.print_debug(agent.str())
	} else if cmd.name == 'generate' {
		agent.generate(name, '')!
		if load {
			agent.load(name)!
		}
	} else if cmd.name == 'load' {
		agent.load(name)!
	} else if cmd.name == 'forget' {
		agent.forget(name)!
	} else if cmd.name == 'reset' {
		agent.reset()!
	} else if cmd.name == 'add' {
		panic("can't work, no support for multiline yet")
		mut myui := ui.new()!
		privkey := myui.ask_question(
			question: 'private key of your ssh key'
		)!
		agent.add(name, privkey)!
	} else {
		// console.print_debug(1)
		return error(cmd.help_message())
		// console.print_debug(" Supported commands are: ${gentools.gencmds}")
		// return error('unknown subcmd')
	}
}
