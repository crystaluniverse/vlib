module stripe

import freeflowuniverse.crystallib.core.base
import freeflowuniverse.crystallib.clients.httpconnection
import freeflowuniverse.crystallib.ui
import freeflowuniverse.crystallib.ui.console
import os

pub struct StripeClient[T] {
	base.Base[T]
pub mut:
	connection &httpconnection.HTTPConnection
}

pub struct Config {
	play.ConfigBase
pub mut:
	configtype string = 'stripeclient' // needs to be defined	
	api_key    string
}

pub fn get(args play.PlayArgs) !StripeClient[Config] {
	con := httpconnection.HTTPConnection{}
	mut client := StripeClient[Config]{
		connection: &con
	}
	client.init(args)!
	return client
}

pub fn heroplay(args play.PLayBookAddArgs) ! {
	// make session for configuring from heroscript
	mut session := play.session_new(session_name: 'config')!
	session.playbook_add(path: args.path, text: args.text, git_url: args.git_url)!
	for mut action in session.plbook.find(filter: 'stripeclient.define')! {
		mut p := action.params
		instance := p.get_default('instance', 'default')!
		mut cl := get(instance: instance)!
		mut cfg := cl.config()!
		cfg.api_key = p.get('api_key')!
		cl.config_save()!
	}
}

pub fn (mut self StripeClient[Config]) config_interactive() ! {
	mut myui := ui.new()!
	console.clear()
	console.print_debug('\n## Configure Stripe Client')
	console.print_debug('========================\n\n')

	mut cfg := self.config()!

	self.instance = myui.ask_question(
		question: 'name for Stripe client'
		default:  self.instance
	)!

	cfg.api_key = myui.ask_question(
		question: 'stripe api_key'
		minlen:   10
		default:  cfg.api_key
	)!

	self.config_save()!
}
