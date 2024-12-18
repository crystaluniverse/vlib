module openai

import freeflowuniverse.crystallib.core.base
import freeflowuniverse.crystallib.core.playbook
import freeflowuniverse.crystallib.ui as gui
import freeflowuniverse.crystallib.clients.httpconnection

// import freeflowuniverse.crystallib.ui.console

pub struct OpenAIClient[T] {
	base.BaseConfig[T]
pub mut:
	connection &httpconnection.HTTPConnection
}

@[params]
pub struct Config {
pub mut:
	openaikey   string @[secret]
	description string
}

pub fn get(instance string, cfg Config) !OpenAIClient[Config] {
	mut self := OpenAIClient[Config]{
		connection: &httpconnection.HTTPConnection{}
	}

	if cfg.openaikey.len > 0 {
		// first the type of the instance, then name of instance, then action
		self.init('openaiclient', instance, .set, cfg)!
	} else {
		self.init('openaiclient', instance, .get)!
	}

	mut conn := httpconnection.new(
		name: 'openai'
		url:  'https://api.openai.com/v1/'
	)!
	conn.default_header.add(.authorization, 'Bearer ${self.config()!.openaikey}')
	// req.add_custom_header('x-disable-pagination', 'True') !

	self.connection = conn
	return self
}

// get a new OpenAI client, will create if it doesn't exist or ask for new configuration
pub fn configure(instance_ string) ! {
	mut cfg := Config{}
	mut ui := gui.new()!

	mut instance := instance_
	if instance == '' {
		instance = ui.ask_question(
			question: 'name for Dagu client'
			default:  instance
		)!
	}

	cfg.openaikey = ui.ask_question(
		question: '\nPlease specify your openai secret (instance:${instance}).'
	)!

	get(instance, cfg)!
}
