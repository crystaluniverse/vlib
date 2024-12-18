module grid

import freeflowuniverse.crystallib.core.base
import freeflowuniverse.crystallib.core.playbook
import freeflowuniverse.crystallib.ui
import freeflowuniverse.crystallib.ui.console

pub struct TFGridClient[T] {
	base.BaseConfig[T]
}

@[params]
pub struct Config {
pub mut:
	mnemonics string @[secret]
	network   string
}

pub fn get(instance string, cfg Config) !TFGridClient[Config] {
	mut self := TFGridClient[Config]{}
	if cfg.mnemonics.len > 0 {
		// first the type of the instance, then name of instance, then action
		self.init('tfgridclient', instance, .set, cfg)!
	} else {
		self.init('tfgridclient', instance, .get)!
	}
	return self
}

pub fn heroplay(mut plbook playbook.PlayBook) ! {
	for mut action in plbook.find(filter: 'tfgridclient.define')! {
		mut p := action.params
		instance := p.get_default('instance', 'default')!
		mut cl := get(instance)!
		mut cfg := cl.config_get()!
		cfg.mnemonics = p.get('mnemonics')!
		cfg.network = p.get('network')!
		cl.config_save()!
	}
}

pub fn (mut self TFGridClient[Config]) config_interactive() ! {
	mut myui := ui.new()!
	// console.clear()
	console.print_debug('\n## Configure TFGrid client')
	console.print_debug('==========================')
	console.print_debug('## Instance: ${self.instance}')
	console.print_debug('==========================\n\n')

	mut cfg := self.config()!

	// self.instance = myui.ask_question(
	// 	question: 'name for configuration instance'
	// 	default: self.instance
	// )!

	cfg.mnemonics = myui.ask_question(
		question: 'please enter your mnemonics here'
		minlen:   24
		default:  cfg.mnemonics
	)!

	cfg.network = myui.ask_dropdown(
		question: 'choose environment'
		items:    envs.values()
	)!

	self.config_save()!
}
