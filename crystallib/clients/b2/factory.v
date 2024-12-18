module b2

import freeflowuniverse.crystallib.core.base
import freeflowuniverse.crystallib.core.playbook
import freeflowuniverse.crystallib.ui
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.lang.python

pub struct B2Client[T] {
	base.BaseConfig[T]
pub mut:
	py python.PythonEnv
}

@[params]
pub struct Config {
pub mut:
	keyid      string
	appkey     string @[secret]
	bucketname string // can be empty is the default
}

pub fn get(instance string, cfg Config) !B2Client[Config] {
	mut py := python.new(name: 'default')! // a python env with name default
	mut self := B2Client[Config]{
		py: py
	}
	if cfg.appkey.len > 0 {
		// first the type of the instance, then name of instance, then action
		self.init('b2lclient', instance, .set, cfg)!
	} else {
		self.init('b2lclient', instance, .get)!
	}
	return self
}

// run heroscript starting from path, text or giturl
//```
// !!b2client.define
//     name:'tf_write_1'
//     description:'ThreeFold Read Write Repo 1
//     keyid:'003e2a7be6357fb0000000001'
//     keyname:'tfrw'
//     appkey:'K003UsdrYOZou2ulBHA8p4KLa/dL2n4'
//
//
// path    string
// text    string
// git_url     string
//```	
pub fn heroplay(mut plbook playbook.PlayBook) ! {
	// make session for configuring from heroscript
	for mut action in plbook.find(filter: 'b2client.define')! {
		mut p := action.params
		instance := p.get_default('instance', 'default')!
		// cfg.keyname = p.get('keyname')!
		mut cl := get(instance,
			keyid:      p.get('keyid')!
			appkey:     p.get('appkey')!
			bucketname: p.get('bucketname')!
		)!
	}
}

pub fn (mut self B2Client[Config]) config_interactive() ! {
	mut myui := ui.new()!
	console.clear()
	console.print_debug('\n## Configure B2 Client')
	console.print_debug('========================\n\n')

	mut cfg := self.config_get()!

	self.instance = myui.ask_question(
		question: 'name for B2 (backblaze) client'
		default:  self.instance
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
