module email

import vweb
import time
import json
import log
import freeflowuniverse.crystallib.ui.console

const agent = 'Email Authentication Controller'

// email authentication controller that be be added to vweb projects
@[heap]
pub struct Controller {
	vweb.Context
	callback string @[vweb_global]
mut:
	authenticator Authenticator @[vweb_global]
}

@[params]
pub struct ControllerParams {
	logger        &log.Logger
	authenticator Authenticator @[required]
}

pub fn new_controller(params ControllerParams) Controller {
	mut app := Controller{
		authenticator: params.authenticator
	}
	return app
}

// route responsible for verifying email, email form should be posted here
@[POST]
pub fn (mut app Controller) send_verification_mail() !vweb.Result {
	config := json.decode(SendMailConfig, app.req.data)!
	app.authenticator.send_verification_mail(config) or { panic(err) }
	return app.ok('')
}

// route responsible for verifying email, email form should be posted here
@[POST]
pub fn (mut app Controller) is_verified() vweb.Result {
	address := app.req.data
	// checks if email verified every 2 seconds
	for {
		if app.authenticator.is_authenticated(address) or { panic(err) } {
			// returns success message once verified
			return app.ok('ok')
		}
		time.sleep(2 * time.second)
	}
	return app.html('timeout')
}

// route responsible for verifying email, email form should be posted here
@[POST]
pub fn (mut app Controller) email_authentication() vweb.Result {
	config_ := json.decode(SendMailConfig, app.req.data) or {
		app.set_status(422, 'Request payload does not follow anticipated formatting.')
		return app.text('Request payload does not follow anticipated formatting.')
	}
	config := if config_.link == '' {
		SendMailConfig{
			...config_
			link: 'http://localhost:8000/email_authenticator/authentication_link'
		}
	} else {
		config_
	}

	app.authenticator.send_verification_mail(config) or { panic(err) }

	// checks if email verified every 2 seconds
	for {
		if app.authenticator.is_authenticated(config.email) or { panic(err) } {
			// returns success message once verified
			return app.ok('ok')
		}
		time.sleep(2 * time.second)
	}
	return app.ok('success!')
}

// route responsible for verifying email, email form should be posted here
@[POST]
pub fn (mut app Controller) verify() vweb.Result {
	config_ := json.decode(SendMailConfig, app.req.data) or {
		app.set_status(422, 'Request payload does not follow anticipated formatting.')
		return app.text('Request payload does not follow anticipated formatting.')
	}

	config := if config_.link == '' {
		SendMailConfig{
			...config_
			link: 'http://localhost:8000/email_authenticator/authentication_link'
		}
	} else {
		config_
	}

	app.authenticator.send_verification_mail(config) or { panic(err) }

	// checks if email verified every 2 seconds
	stopwatch := time.new_stopwatch()
	for stopwatch.elapsed() < 180 * time.second {
		authenticated := app.authenticator.is_authenticated(config.email) or {
			return app.text(err.msg())
		}
		if authenticated {
			console.print_debug('heyo yess')
			return app.ok('success')
		}
		time.sleep(2 * time.second)
	}

	app.set_status(408, 'Email authentication timeout.')
	return app.text('Email authentication timeout.')
}

pub struct AuthAttempt {
pub:
	ip      string
	address string
	cypher  string
}

@[POST]
pub fn (mut app Controller) authenticate() !vweb.Result {
	attempt := json.decode(AuthAttempt, app.req.data)!
	app.authenticator.authenticate(attempt.address, attempt.cypher) or {
		app.set_status(401, err.msg())
		return app.text('Failed to authenticate')
	}
	return app.ok('Authentication successful')
}

@['/authentication_link/:address/:cypher']
pub fn (mut app Controller) authentication_link(address string, cypher string) !vweb.Result {
	app.authenticator.authenticate(address, cypher) or {
		app.set_status(401, err.msg())
		return app.text('Failed to authenticate')
	}
	return app.html('Authentication successful')
}
