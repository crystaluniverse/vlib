module auth

import freeflowuniverse.crystallib.web.auth.jwt
import freeflowuniverse.crystallib.web.auth.email
import freeflowuniverse.crystallib.web.auth.session
import freeflowuniverse.crystallib.web.auth.tokens
import freeflowuniverse.crystallib.web.auth.authorization
import freeflowuniverse.crystallib.web.auth.analytics
import freeflowuniverse.crystallib.web.auth.identity
import net.http
import time
import log
import rand
import db.sqlite
import vweb

// Authenticator deals and authenticates refresh and access tokens
pub struct Authenticator {
	// vweb.Context
	refresh_secret string = jwt.create_secret() // secret used for signing/verifying refresh tokens
	access_secret  string = jwt.create_secret() // secret used for signing/verifying refresh tokens
pub mut:
	identity identity.IdentityManager
	email    ?email.Authenticator
	// analytics  analytics.Analyzer
	authorizer authorization.Authorizer
	session    session.SessionAuth
	tokens     tokens.Tokens
	route      string
	// backend   DatabaseBackend
	logger &log.Logger = &log.Logger(&log.Log{
	level: .debug
})
}

// Authenticator deals and authenticates refresh and access tokens
pub struct Authenticator2 {
	// vweb.Context
	refresh_secret string = jwt.create_secret() // secret used for signing/verifying refresh tokens
	access_secret  string = jwt.create_secret() // secret used for signing/verifying refresh tokens
pub mut:
	identity identity.IdentityManager
	email    ?email.Authenticator
	// analytics  analytics.Analyzer
	authorizer authorization.Authorizer
	session    session.SessionAuth
	tokens     tokens.Tokens
	route      string
	// backend   DatabaseBackend
	logger &log.Logger = &log.Logger(&log.Log{
	level: .debug
})
}

@[params]
pub struct AuthenticatorConfig {
	email.AuthenticatorConfig
	refresh_secret string = jwt.create_secret() // secret used for signing/verifying refresh tokens
	access_secret  string = jwt.create_secret() // secret used for signing/verifying refresh tokens
	authorizer     authorization.Authorizer
	// backend        DatabaseBackend [required]
	logger &log.Logger = &log.Logger(&log.Log{
	level: .debug
})
}

pub fn new(config AuthenticatorConfig) !Authenticator {
	return Authenticator{
		identity: identity.new()!
		// analytics: analytics.new()!
		access_secret: config.access_secret
		session: session.new()!
		refresh_secret: config.refresh_secret
		// backend: new_database_backend()!
		logger: config.logger
		email: email.new(
			smtp: config.smtp
			backend: email.new_database_backend()!
		)!
		authorizer: config.authorizer
	}
}
