module email

import log

// Creates and updates, authenticates email authentication sessions
interface IBackend {
	read_auth_session(string) ?AuthSession
mut:
	logger &log.Logger
	create_auth_session(AuthSession) !
	update_auth_session(AuthSession) !
	delete_auth_session(string) !
	set_session_authenticated(string) !
}
