module mailclient

import freeflowuniverse.crystallib.core.base
import freeflowuniverse.crystallib.core.playbook

__global (
	mailclient_global  map[string]&MailClient
	mailclient_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name string = 'default'
}

fn args_get(args_ ArgsGet) ArgsGet {
	mut args := args_
	if args.name == '' {
		args.name = mailclient_default
	}
	if args.name == '' {
		args.name = 'default'
	}
	return args
}

pub fn get(args_ ArgsGet) !&MailClient {
	mut args := args_get(args_)
	if args.name !in mailclient_global {
		if !config_exists() {
			if default {
				config_save()!
			}
		}
		config_load()!
	}
	return mailclient_global[args.name] or { panic('bug') }
}

// switch instance to be used for mailclient
pub fn switch(name string) {
	mailclient_default = name
}

fn config_exists(args_ ArgsGet) bool {
	mut args := args_get(args_)
	mut context := base.context() or { panic('bug') }
	return context.hero_config_exists('mailclient', args.name)
}

fn config_load(args_ ArgsGet) ! {
	mut args := args_get(args_)
	mut context := base.context()!
	mut heroscript := context.hero_config_get('mailclient', args.name)!
	play(heroscript: heroscript)!
}

fn config_save(args_ ArgsGet) ! {
	mut args := args_get(args_)
	mut context := base.context()!
	context.hero_config_set('mailclient', args.name, heroscript_default())!
}

fn set(o MailClient) ! {
	mut o2 := obj_init(o)!
	mailclient_global['default'] = &o2
}

@[params]
pub struct InstallPlayArgs {
pub mut:
	name       string = 'default'
	heroscript string // if filled in then plbook will be made out of it
	plbook     ?playbook.PlayBook
	reset      bool
	start      bool
	stop       bool
	restart    bool
	delete     bool
	configure  bool // make sure there is at least one installed
}

pub fn play(args_ InstallPlayArgs) ! {
	mut args := args_
	println('debguzo1')
	mut plbook := args.plbook or {
		println('debguzo2')
		heroscript := if args.heroscript == '' {
			heroscript_default()
		} else {
			args.heroscript
		}
		playbook.new(text: heroscript)!
	}

	mut install_actions := plbook.find(filter: 'mailclient.configure')!
	println('debguzo3 ${install_actions}')
	if install_actions.len > 0 {
		for install_action in install_actions {
			mut p := install_action.params
			cfg_play(p)!
		}
	}
}
