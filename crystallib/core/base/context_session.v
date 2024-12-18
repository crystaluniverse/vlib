module base

import freeflowuniverse.crystallib.data.ourtime
import freeflowuniverse.crystallib.data.paramsparser
import json

@[params]
pub struct SessionConfig {
pub mut:
	name        string // unique name for session (id), there can be more than 1 session per context
	start       string // can be e.g. +1h
	description string
	params      string
}

// get a session object based on the name /
// params:
// ```
// name string
// ```
pub fn (mut context Context) session_new(args_ SessionConfig) !Session {
	mut args := args_
	if args.name == '' {
		args.name = ourtime.now().key()
	}

	if args.start == '' {
		t := ourtime.new(args.start)!
		args.start = t.str()
	}

	mut r := context.redis()!

	rkey := 'sessions:config:${args.name}'

	config_json := json.encode(args)

	r.set(rkey, config_json)!

	rkey_latest := 'sessions:config:latest'
	r.set(rkey_latest, args.name)!

	return context.session_get(name: args.name)!
}

@[params]
pub struct ContextSessionGetArgs {
pub mut:
	name string
}

pub fn (mut context Context) session_get(args_ ContextSessionGetArgs) !Session {
	mut args := args_
	mut r := context.redis()!

	if args.name == '' {
		rkey_latest := 'sessions:config:latest'
		args.name = r.get(rkey_latest)!
	}
	rkey := 'sessions:config:${args.name}'
	mut datajson := r.get(rkey)!
	if datajson == '' {
		if args.name == '' {
			return context.session_new()!
		} else {
			return error("can't find session with name ${args.name}")
		}
	}
	config := json.decode(SessionConfig, datajson)!
	t := ourtime.new(config.start)!
	mut s := Session{
		name:    args.name
		start:   t
		context: &context
		params:  paramsparser.new(config.params)!
		config:  config
	}
	return s
}

pub fn (mut context Context) session_latest() !Session {
	mut r := context.redis()!
	rkey_latest := 'sessions:config:latest'
	latestname := r.get(rkey_latest)!
	if latestname == '' {
		return context.session_new()!
	}
	return context.session_get(name: latestname)!
}
