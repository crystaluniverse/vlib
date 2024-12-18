module base

import freeflowuniverse.crystallib.data.ourtime
// import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.data.paramsparser
import freeflowuniverse.crystallib.data.dbfs
import json
// import freeflowuniverse.crystallib.core.pathlib
// import freeflowuniverse.crystallib.develop.gittools
// import freeflowuniverse.crystallib.ui.console

@[heap]
pub struct Session {
pub mut:
	name        string // unique id for session (session id), can be more than one per context
	interactive bool = true
	params      paramsparser.Params
	start       ourtime.OurTime
	end         ourtime.OurTime
	context     &Context @[skip; str: skip]
	config      SessionConfig
	env         map[string]string
}

///////// LOAD & SAVE

// fn (mut self Session) key() string {
// 	return 'hero:sessions:${self.guid()}'
// }

// get db of the session, is unique per session
pub fn (mut self Session) db_get() !dbfs.DB {
	return self.context.db_get('session_${self.name}')!
}

// get the db of the config, is unique per context
pub fn (mut self Session) db_config_get() !dbfs.DB {
	return self.context.db_get('config')!
}

// load the params from redis
pub fn (mut self Session) load() ! {
	mut r := self.context.redis()!
	rkey := 'sessions:config:${self.name}'
	mut datajson := r.get(rkey)!
	if datajson == '' {
		return error("can't find session with name ${self.name}")
	}
	self.config = json.decode(SessionConfig, datajson)!
	self.params = paramsparser.new(self.config.params)!
}

// save the params to redis
pub fn (mut self Session) save() ! {
	self.check()!
	rkey := 'sessions:config:${self.name}'
	mut r := self.context.redis()!
	self.config.params = self.params.str()
	config_json := json.encode(self.config)
	r.set(rkey, config_json)!
}

// Set an environment variable
pub fn (mut self Session) env_set(key string, value string) ! {
	self.env[key] = value
	self.save()!
}

// Get an environment variable
pub fn (mut self Session) env_get(key string) !string {
	return self.env[key] or { return error("can't find env in session ${self.name}") }
}

// Delete an environment variable
pub fn (mut self Session) env_delete(key string) {
	self.env.delete(key)
}

////////// REPRESENTATION

pub fn (self Session) check() ! {
	if self.name.len < 3 {
		return error('name should be at least 3 char')
	}
}

pub fn (self Session) guid() string {
	return '${self.context.guid()}:${self.name}'
}

fn (self Session) str2() string {
	mut out := 'session:${self.guid()}'
	out += ' start:\'${self.start}\''
	if !self.end.empty() {
		out += ' end:\'${self.end}\''
	}
	return out
}
