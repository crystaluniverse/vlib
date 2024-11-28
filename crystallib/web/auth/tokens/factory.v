module tokens

import freeflowuniverse.crystallib.web.auth.jwt
import log

// Authenticator deals and authenticates refresh and access tokens
pub struct Tokens {
	refresh_secret string = jwt.create_secret() // secret used for signing/verifying refresh tokens
	access_secret  string = jwt.create_secret() // secret used for signing/verifying refresh tokens
mut:
	logger &log.Logger = &log.Logger(&log.Log{
	level: .debug
})
}

@[params]
pub struct TokensConfig {
	refresh_secret string      = jwt.create_secret() // secret used for signing/verifying refresh tokens
	access_secret  string      = jwt.create_secret() // secret used for signing/verifying refresh tokens
	logger         &log.Logger = &log.Logger(&log.Log{
	level: .debug
})
}
