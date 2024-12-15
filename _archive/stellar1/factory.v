module stellar

import freeflowuniverse.crystallib.core.base
import freeflowuniverse.crystallib.ui
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.lang.python

pub struct StellarClient[T] {
	play.BaseConfig[T]
pub mut:
	py python.PythonEnv
}

pub struct Config {
	play.ConfigBase
pub mut:
	configtype  string = 'stellarclient' // needs to be defined	
	keyname     string
	secret      string
	description string
}

// get instance of our client params: .
// instance string = "default".
// playargs ?PlayArgs (defines how to get session and/or context)
//
pub fn get(args play.PlayArgs) !StellarClient[Config] {
	mut py := python.new(name: 'default')! // a python env with name default
	mut client := StellarClient[Config]{
		py: py
	}
	client.init(args)!
	return client
}

// run heroscript starting from path, text or giturl
//```
// !!stellarclient.define
//     name:'tf_write_1'
//     description:'ThreeFold Read Write Repo 1
//     secret:'...'
//
//
// path    string
// text    string
// git_url     string
//```	
pub fn heroplay(args play.PLayBookAddArgs) ! {
	// make session for configuring from heroscript
	mut session := play.session_new(session_name: 'config')!
	session.playbook_add(path: args.path, text: args.text, git_url: args.git_url)!
	for mut action in session.plbook.find(filter: 'stellarclient.define')! {
		mut p := action.params
		instance := p.get_default('instance', 'default')!
		mut cl := get(instance: instance)!
		mut cfg := cl.config()!
		cfg.description = p.get('description')!
		cfg.secret = p.get('secret')!
		cl.config_save()!
	}
}

pub fn (mut self StellarClient[Config]) config_interactive() ! {
	mut myui := ui.new()!
	console.clear()
	console.print_debug('\n## Configure Stellar Client')
	console.print_debug('========================\n\n')

	mut cfg := self.config()!

	self.instance = myui.ask_question(
		question: 'name for stellar client'
		default: self.instance
	)!

	cfg.description = myui.ask_question(
		question: 'description'
		minlen: 0
		default: cfg.description
	)!
	cfg.secret = myui.ask_question(
		question: 'secret e.g. ...'
		minlen: 5
		default: cfg.secret
	)!

	// buckets := self.list_buckets()!
	// bucket_names := buckets.map(it.name)

	// cfg.bucketname = myui.ask_dropdown(
	// 	question: 'choose default bucket name'
	// 	items: bucket_names
	// )!

	self.config_save()!
}
