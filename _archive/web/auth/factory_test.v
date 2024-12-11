module main

// import freeflowuniverse.spiderlib.auth.jwt
// import freeflowuniverse.crystallib.web.auth.email
// import freeflowuniverse.crystallib.web.auth.authorization
// import freeflowuniverse.crystallib.web.auth.analytics
// import freeflowuniverse.crystallib.web.auth.identity
// import net.http
// import time
// import log
// import rand
// import db.sqlite
import vweb

// Authenticator deals and authenticates refresh and access tokens
pub struct Authenticator1 {
	vweb.Context // refresh_secret string = jwt.create_secret() // secret used for signing/verifying refresh tokens
	// access_secret  string = jwt.create_secret() // secret used for signing/verifying refresh tokens
	// pub mut:
	// identity  identity.IdentityManager     @[vweb_global]
	// email     email.Authenticator
	// analytics analytics.Analytics
	// authorizer authorization.Authorizer
	// backend   DatabaseBackend
	// logger    &log.Logger = &log.Logger(&log.Log{
	// level: .debug
	// })
}

@[params]
pub struct Authenticator1Config {
	// refresh_secret string = jwt.create_secret() // secret used for signing/verifying refresh tokens
	// access_secret  string = jwt.create_secret() // secret used for signing/verifying refresh tokens
	// authorizer       authorization.Authorizer
	// backend        DatabaseBackend [required]
	// 	logger &log.Logger = &log.Logger(&log.Log{
	// 	level: .debug
	// })
}

pub fn new1(config Authenticator1Config) !Authenticator1 {
	return Authenticator1{
		// identity: identity.new()!
		// analytics: analytics.new()!
		// access_secret: config.access_secret
		// refresh_secret: config.refresh_secret
		// backend: new_database_backend()!
		// logger: config.logger
		// email: email.new(backend: email.new_database_backend()!)
		// authorizer: config.authorizer
	}
}

fn test_new() {
	auth := new1()!
}
