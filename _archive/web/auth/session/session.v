module session

import db.sqlite
import log
import rand
import freeflowuniverse.crystallib.ui.console

pub struct SessionAuth {
mut:
	backend DatabaseBackend
}

pub fn (mut s SessionAuth) create_session(user_id string) Session {
	sesh_id := rand.uuid_v4()
	sesh := Session{
		session_id: sesh_id
		user_id:    user_id
	}
	s.backend.add_session(sesh)
	return sesh
}

pub fn (mut s SessionAuth) get_session(id string) ?Session {
	return s.backend.get_session(id)
}

// Creates and updates, authenticates email authentication sessions
@[noinit]
struct DatabaseBackend {
mut:
	db     sqlite.DB
	logger &log.Logger = &log.Logger(&log.Log{
	level: .info
})
}

// struct UserSessions {
// 	id       int       @[primary]
// 	user_id  string
// 	sessions []Session @[fkey: 'fid']
// }

struct Session {
pub:
	session_id string @[primary]
	user_id    string
}

@[params]
pub struct DatabaseBackendConfig {
	db_path string = 'session_authenticator.sqlite'
mut:
	// db     sqlite.DB
	logger &log.Logger = &log.Logger(&log.Log{
	level: .info
})
}

pub fn new_database_backend(config DatabaseBackendConfig) !DatabaseBackend {
	db := sqlite.connect(config.db_path) or { panic(err) }
	// create table UserSessions
	sql db {
		create table Session
	} or { panic(err) }

	return DatabaseBackend{
		// logger: config.logger
		db: db
	}
}

pub fn sqlite_database_backend(db sqlite.DB) !DatabaseBackend {
	// create table UserSessions
	sql db {
		create table Session
	} or { panic(err) }

	return DatabaseBackend{
		// logger: config.logger
		db: db
	}
}

// add session id iadds the id of a session to the user's sessions
fn (mut backend DatabaseBackend) add_session(session Session) {
	console.print_debug('adding sesh: ${session}')
	session_ := Session{
		session_id: 'sessionid'
		user_id:    'userid'
	}
	sql backend.db {
		insert session into Session
	} or { panic('err:${err}') }
}

// add session adds the id of a session to the user's sessions
fn (mut backend DatabaseBackend) session_exists(id string) bool {
	sessions := sql backend.db {
		select from Session where session_id == id
	} or { panic('err:${err}') }
	if sessions.len > 1 {
		panic('this should never happen')
	}
	return sessions.len == 1
}

// add session id iadds the id of a session to the user's sessions
fn (mut backend DatabaseBackend) delete_session(id string) {
	sql backend.db {
		delete from Session where session_id == id
	} or { panic('err:${err}') }
}

// // add session id iadds the id of a session to the user's sessions
// fn (mut backend DatabaseBackend) add_user(user_id string) {
// 	user_sessions := UserSessions{
// 		user_id: user_id
// 		sessions: [
// 			Session{
// 				user_id: user_id
// 				session_id: 'gibberish'
// 				fid: 1
// 			},
// 		]
// 	}
// 	sql backend.db {
// 		insert user_sessions into UserSessions
// 	} or { panic('err:${err}') }
// }

// // add session id iadds the id of a session to the user's sessions
// fn (mut backend DatabaseBackend) user_exists(user_id string) bool {
// 	users := sql backend.db {
// 		select from UserSessions where user_id == user_id
// 	} or { panic('err:${err}') }
// 	if users.len > 1 {
// 		panic('this should never happen')
// 	}
// 	return users.len == 1
// }

// // add session id iadds the id of a session to the user's sessions
// fn (mut backend DatabaseBackend) get_user(user_id string) ?string {
// 	users := sql backend.db {
// 		select from UserSessions where user_id == user_id
// 	} or { panic('err:${err}') }
// 	if users.len > 1 {
// 		panic('this should never happen')
// 	}

// 	if users.len < 1 {
// 		return none
// 	}
// 	return users[0].user_id
// }

// add session id iadds the id of a session to the user's sessions
fn (mut backend DatabaseBackend) get_session(id string) ?Session {
	sessions := sql backend.db {
		select from Session where session_id == id
	} or { panic('err:${err}') }
	if sessions.len > 1 {
		panic('this should never happen')
	}

	if sessions.len < 1 {
		return none
	}
	return sessions[0]
}
