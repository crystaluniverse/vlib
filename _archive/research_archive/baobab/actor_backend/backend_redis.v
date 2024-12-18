module actionsexecutor

import json
import db.sqlite
import freeflowuniverse.crystallib.clients.redisclient

pub struct RedisBackend {
	redis redisclient.Redis
}

// save the session to redis & mem
pub fn (mut backend RedisBackend) get[T](id string) ?T {
	mut r := redisclient.core_get()!
	if session.sid.len == 2 {
		return error('sid should be at least 2 char')
	}
	t := r.hget('session.${session.context.id}', session.sid)!
	if t == '' {
		return
	}
	p := paramsparser.new(t)!
	if session.name == '' {
		session.name = p.get_default('name', '')!
	}
	session.start = p.get_time_default('start', session.start)!
	session.end = p.get_time_default('end', session.end)!
}
