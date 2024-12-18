module identity

import db.sqlite
import freeflowuniverse.crystallib.ui.console

pub struct IdentityManager {
mut:
	backend DBBackend
}

pub fn new() !IdentityManager {
	return IdentityManager{
		backend: new_backend()!
	}
}

// pub struct User {
// pub:
// 	id string @[primary]
// pub mut:
// 	email string
// }

pub fn (mut auth IdentityManager) login_user(email string) !User {
	return auth.backend.read_user(email: email) or { return error('user not found') }
}

pub fn (mut auth IdentityManager) register_user(identifier string) User {
	return auth.backend.create_user(identifier)
}

pub fn (mut auth IdentityManager) get_user(user User) ?User {
	return auth.backend.read_user(
		id:    user.id
		email: user.email
	) or { return none }
}

pub fn (mut auth IdentityManager) get_users() ![]User {
	console.print_debug('getting users')
	return auth.backend.read_users()!
}
