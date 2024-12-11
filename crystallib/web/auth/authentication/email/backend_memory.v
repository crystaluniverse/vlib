module email

import log

// // Creates and updates, authenticates email authentication sessions
// @[noinit]
// struct MemoryBackend {
// mut:
// 	sessions map[string]AuthSession
// 	logger   &log.Logger = &log.Logger(&log.Log{
// 	level: .info
// })
// }

// // factory for
// pub fn new_memory_backend() !MemoryBackend {
// 	return MemoryBackend{}
// }

// fn (mut backend MemoryBackend) create_auth_session(session AuthSession) ! {
// 	backend.sessions[session.email] = session
// }

// fn (backend MemoryBackend) read_auth_session(email string) ?AuthSession {
// 	return backend.sessions[email] or { return none }
// }

// fn (mut backend MemoryBackend) update_auth_session(session AuthSession) ! {
// 	backend.sessions[session.email] = session
// }

// fn (mut backend MemoryBackend) set_session_authenticated(email string) ! {
// 	backend.sessions[email].authenticated = true
// }

// fn (mut backend MemoryBackend) delete_auth_session(email string) ! {
// 	backend.sessions.delete(email)
// }
