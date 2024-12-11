module auth

import json
import freeflowuniverse.crystallib.web.auth.email
import vweb
import toml
import os

pub struct AuthServer {
	vweb.Context
mut:
	auth Authenticator @[vweb_global]
}

pub fn new_server(config AuthenticatorConfig) !AuthServer {
	env := toml.parse_file(os.dir(@FILE) + '/.env') or { panic('Could not find .env, ${err}') }
	return AuthServer{
		auth: new(config)!
	}
}

pub fn (mut server AuthServer) index() vweb.Result {
	return server.html('')
}

@[POST]
pub fn (mut ctrl AuthServer) register() vweb.Result {
	identifier := ctrl.req.data
	if identifier == '' {
		ctrl.set_status(400, '')
		return ctrl.text('Failed to decode json, error')
	}
	response := ctrl.auth.register(identifier) or {
		ctrl.set_status(400, '')
		return ctrl.text('error: ${err}')
	}
	return ctrl.json(response)
}

@[POST]
pub fn (mut ctrl AuthServer) login_challenge() vweb.Result {
	identifier := ctrl.req.data
	config := json.decode(email.SendMailConfig, ctrl.req.data) or {
		ctrl.set_status(400, '')
		return ctrl.text('Failed to decode json, error: ${err}')
	}
	ctrl.auth.login_challenge(config) or {
		ctrl.set_status(400, '')
		return ctrl.text('error: ${err}')
	}
	return ctrl.text('ok')
}

@[POST]
pub fn (mut ctrl AuthServer) login() vweb.Result {
	identifier := ctrl.req.data
	if identifier == '' {
		ctrl.set_status(400, '')
		return ctrl.text('Failed to decode json, error')
	}
	response := ctrl.auth.register(identifier) or {
		ctrl.set_status(400, '')
		return ctrl.text('error: ${err}')
	}
	return ctrl.json(response)
}

@[POST]
pub fn (mut ctrl AuthServer) authenticate() vweb.Result {
	// todo
	ctrl.auth.authenticate('') or {
		ctrl.set_status(400, '')
		return ctrl.text('error: ${err}')
	}
	return ctrl.ok('')
}

pub fn (mut ctrl AuthServer) get_user() vweb.Result {
	// todo
	response := ctrl.auth.get_user('') or {
		ctrl.set_status(400, '')
		return ctrl.text('error: ${err}')
	}
	return ctrl.json(response)
}
