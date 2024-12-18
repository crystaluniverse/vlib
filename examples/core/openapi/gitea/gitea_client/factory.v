module dagu

// import os
import freeflowuniverse.crystallib.clients.httpconnection
import os

struct GiteaClient[T] {
	base.Base[T]
mut:
	connection &httpconnection.HTTPConnection
}

struct Config {
	play.ConfigBase[T]
	url string
}

//
pub fn get(args PlayArgs) GiteaClient[Config] {
	mut client := GiteaClient[Config]{}
	client.init(args)!
	return client
}

//
pub fn heroplay(args PlayBookAddArgs) ! {
	// make session for configuring from heroscript
	mut session := play.session_new(session_name: 'config')!
	session.playbook_add(path: args.path, text: args.text, git_url: args.git_url)!
	for mut action in session.plbook.find(filter: 'gitea_client.define')! {
		mut p := action.params
		instance := p.get_default('instance', 'default')!
		mut cl := get(instance: instance)!
		mut cfg := cl.config()!
		mut config := p.decode[T]()!
		cl.config_save()!
	}
}

//
pub fn (self GiteaClient[T]) config_interactive() ! {
	mut myui := ui.new()!
	console.clear()
	println('
## Configure B2 Client')
	println('========================

')

	mut cfg := self.config()!

	self.instance = myui.ask_question(
		question: 'name for B2 (backblaze) client'
		default:  self.instance
	)!

	cfg.description = myui.ask_question(
		question: 'description'
		minlen:   0
		default:  cfg.description
	)!
	cfg.keyid = myui.ask_question(
		question: 'keyid e.g. 003e2a7be6357fb0000000001'
		minlen:   5
		default:  cfg.keyid
	)!

	cfg.appkey = myui.ask_question(
		question: 'appkey e.g. K008UsdrYOAou2ulBHA8p4KBe/dL2n4'
		minlen:   5
		default:  cfg.appkey
	)!

	buckets := self.list_buckets()!
	bucket_names := buckets.map(it.name)

	cfg.bucketname = myui.ask_dropdown(
		question: 'choose default bucket name'
		items:    bucket_names
	)!

	self.config_save()!
}
