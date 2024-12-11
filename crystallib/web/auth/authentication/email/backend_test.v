module email

import db.sqlite
import log
import time

const test_email = 'test@example.com'

const test_auth_code = '123ABC'

const test_db_name = 'email_authenticator.sqlite'

fn testsuite_begin() {
	db := sqlite.connect(email.test_db_name) or { panic(err) }
	sql db {
		drop table AuthSession
	} or { return }
}

fn testsuite_end() {
	db := sqlite.connect(email.test_db_name) or { panic(err) }
	sql db {
		drop table AuthSession
	} or { panic(err) }
}

fn test_database_backend() {
	mut backend := new_database_backend()!
	run_backend_tests(mut backend)!
	backend.db.close()!
}

fn test_memory_backend() {
	mut backend := new_memory_backend()!
	run_backend_tests(mut backend)!
}

fn run_backend_tests(mut backend IBackend) ! {
	session := AuthSession{
		email: email.test_email
	}

	backend.create_auth_session(session)!
	assert backend.read_auth_session(email.test_email)! == session

	backend.update_auth_session(AuthSession{
		...session
		attempts_left: 1
	})!
	assert backend.read_auth_session(email.test_email)!.attempts_left == 1

	backend.delete_auth_session(email.test_email)!
	if _ := backend.read_auth_session(email.test_email) {
		// should return none, so fails test
		assert false
	} else {
		assert true
	}
}
