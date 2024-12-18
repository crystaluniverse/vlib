module redisdb

import freeflowuniverse.crystallib.data.paramsparser
import freeflowuniverse.crystallib.develop.gittools
import freeflowuniverse.crystallib.data.ourtime
import freeflowuniverse.crystallib.clients.redisclient
import freeflowuniverse.crystallib.core.texttools
import json

pub struct Base {
pub mut:
	cid       string
	id        string // unique id for session (session id), there can be more than 1 per id
	name      string
	init_time ourtime.OurTime
	mod_time  ourtime.OurTime
	contextid string
	params    string
}

pub struct Session {
	Base
pub mut:
	a string
	y map[string]string
}

fn get_data(ro_name string, cid string, id string) !string {
	mut r := redisclient.core_get()!
	if id == '' {
		panic('id should always be filled in. Bug.')
	}
	if cid == '' {
		panic('cid should always be filled in. Bug.')
	}
	return r.hget('db:${cid}:sessions', id)!
}

pub fn (mut base Base) set_data(ro_name string, ro_data string) ! {
	mut r := redisclient.core_get()!
	if base.id == '' {
		// TODO: fix this
		// base.id = ...
	}
	if base.cid == '' {
		panic('session cid should always be filled in. Bug.')
	}
	r.hset('db:${cid}:sessions', base.id, ro_data)!
}

// if sessoin gets returned without id, then we know its a new one
pub fn session_get(cid string, id string) !Session {
	data := get_data('session', cid, id)!
	if data == '' {
		return Session{
			cid: cid
		} // id is empty this means new object
	}
	return json.decode(Session, data) or { return error('Cannot decode session.\n${data}') }
}

pub fn (mut session Session) set() ! {
	data := json.encode(session)
	session.set_data('session', data)!
}

// pub session_list() ! {
// 	mut r := redisclient.core_get()!
// 	mut session:=session_
// 	if session.id == ""{
// 		session.id = ...
// 	}
// 	if session.cid == ""{
// 		panic("session cid should always be filled in. Bug.")
// 	}	
// 	data:=json.encode()
// 	r.hset('db:${cid}:sessions', id,data)!
// }
