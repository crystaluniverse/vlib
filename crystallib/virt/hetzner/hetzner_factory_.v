module hetzner

import freeflowuniverse.crystallib.core.base
import freeflowuniverse.crystallib.core.playbook
import freeflowuniverse.crystallib.ui.console

__global (
	hetzner_global  map[string]&HetznerManager
	hetzner_default string
)

/////////FACTORY

@[params]
pub struct ArgsGet {
pub mut:
	name string
}

fn args_get(args_ ArgsGet) ArgsGet {
	mut args := args_
	if args.name == '' {
		args.name = hetzner_default
	}
	if args.name == '' {
		args.name = 'default'
	}
	return args
}

pub fn get(args_ ArgsGet) !&HetznerManager {
	mut args := args_get(args_)
	if args.name !in hetzner_global {
		if args.name == 'default' {
			if !config_exists(args) {
				if default {
					config_save(args)!
				}
			}
			config_load(args)!
		}
	}
	return hetzner_global[args.name] or {
		println(hetzner_global)
		panic('could not get config for hetzner with name:${args.name}')
	}
}

fn config_exists(args_ ArgsGet) bool {
	mut args := args_get(args_)
	mut context := base.context() or { panic('bug') }
	return context.hero_config_exists('hetzner', args.name)
}

fn config_load(args_ ArgsGet) ! {
	mut args := args_get(args_)
	mut context := base.context()!
	mut heroscript := context.hero_config_get('hetzner', args.name)!
	play(heroscript: heroscript)!
}

fn config_save(args_ ArgsGet) ! {
	mut args := args_get(args_)
	mut context := base.context()!
	context.hero_config_set('hetzner', args.name, heroscript_default()!)!
}

fn set(o HetznerManager) ! {
	mut o2 := obj_init(o)!
	hetzner_global[o.name] = &o2
	hetzner_default = o.name
}

@[params]
pub struct PlayArgs {
pub mut:
	heroscript string // if filled in then plbook will be made out of it
	plbook     ?playbook.PlayBook
	reset      bool
}

pub fn play(args_ PlayArgs) ! {
	mut args := args_

	if args.heroscript == '' {
		args.heroscript = heroscript_default()!
	}
	mut plbook := args.plbook or { playbook.new(text: args.heroscript)! }

	mut install_actions := plbook.find(filter: 'hetzner.configure')!
	if install_actions.len > 0 {
		for install_action in install_actions {
			mut p := install_action.params
			mycfg := cfg_play(p)!
			console.print_debug('install action hetzner.configure\n${mycfg}')
			set(mycfg)!
		}
	}
}

// switch instance to be used for hetzner
pub fn switch(name string) {
	hetzner_default = name
}
