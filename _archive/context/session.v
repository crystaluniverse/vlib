module context

import freeflowuniverse.crystallib.data.ourtime
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.clients.redisclient
import freeflowuniverse.crystallib.data.paramsparser

pub struct Session {
pub mut:
	sid     string // unique id for session (session id), can be more than one per context
	name    string
	start   ourtime.OurTime
	end     ourtime.OurTime
	context Context @[skip; str: skip]
}

@[params]
pub struct SessionNewArgs {
pub mut:
	sid   string // unique id for session (session id), there can be more than 1 per id
	name  string
	start string // can be e.g. +1h
	load  bool = true // get it from the redis backend
	save  bool
}

// get a session object based on the name /
// params:
// ```
// uid	string //unique id
// name string
// start string  //can be e.g. +1h
// ```
pub fn (context Context) get(args_ SessionNewArgs) !Session {
	mut args := args_
	args.name = texttools.name_fix(args.name)
	t := ourtime.new(args.start)!
	mut s := Session{
		sid:     args.sid
		name:    args.name
		start:   t
		context: &context
	}
	if args.load {
		s.load()!
	}
	if args.save {
		s.save()!
	}
	return s
}

// // save the session to redis & mem
// pub fn (mut session Session) load() ! {
// 	mut r := redisclient.core_get()!
// 	if session.sid.len == 2 {
// 		return error('sid should be at least 2 char')
// 	}
// 	t := r.hget('session.${session.context.id}', session.sid)!
// 	if t == '' {
// 		return
// 	}
// 	p := paramsparser.new(t)!
// 	if session.name == '' {
// 		session.name = p.get_default('name', '')!
// 	}
// 	session.start = p.get_time_default('start', session.start)!
// 	session.end = p.get_time_default('end', session.end)!
// }

// // save the session to redis & mem
// pub fn (session Session) save() ! {
// 	mut r := redisclient.core_get()!
// 	r.hset('session.${session.context.id}', session.sid, session.str2())!
// }

// // save the session to redis & mem
// pub fn (session Session) str() string {
// 	return '!!context.session_define ${session.str2()}'
// }

// fn (session Session) str2() string {
// 	mut out := 'id:${session.context.id} sid:${session.sid}'
// 	if session.name.len > 0 {
// 		out += ' name:${session.name}'
// 	}
// 	out += ' start:${session.start}'
// 	if !session.end.empty() {
// 		out += ' end:${session.end}'
// 	}
// 	return out
// }
