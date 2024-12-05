module tokens

import time
import log
import freeflowuniverse.crystallib.web.auth.jwt { SignedJWT }

@[params]
pub struct TokenParams {
pub:
	user_id  string
	subject  string
	issuer   string
	audience string
}

@[params]
pub struct RefreshTokenParams {
	TokenParams
pub:
	expiration time.Time = time.now().add_days(30)
}

// secret := os.getenv('SECRET_KEY')

pub struct AuthTokens {
pub:
	access_token  string
	refresh_token string
}

pub fn (mut auth Tokens) new_auth_tokens(params RefreshTokenParams) AuthTokens {
	auth.logger.debug('Session authenticator: creating new auth tokens')
	refresh_token := auth.new_refresh_token(params)
	access_token := auth.new_access_token(refresh_token: refresh_token) or { panic(err) }
	return AuthTokens{
		access_token: access_token
		refresh_token: refresh_token
	}
}

pub fn (mut auth Tokens) new_refresh_token(params RefreshTokenParams) string {
	auth.logger.debug('Session authenticator: creating new refresh token')

	token := jwt.create_token(
		sub: params.subject
		iss: params.issuer
		exp: params.expiration
	)

	signed_token := token.sign(auth.refresh_secret)
	auth.logger.debug('Session authenticator: created refresh token: ${signed_token}')
	return signed_token
}

@[params]
pub struct AccessTokenParams {
	expiration    time.Time = time.now().add(15 * time.minute)
	refresh_token SignedJWT @[required]
}

pub fn (mut auth Tokens) new_access_token(params AccessTokenParams) !string {
	if !auth.authenticate_refresh_token(params.refresh_token)! {
		auth.logger.info('Session authenticator: Failed to authenticate refresh token')
		return error('Refresh token not authenticated')
	}
	refresh_token := params.refresh_token.decode()!
	token := jwt.create_token(
		sub: refresh_token.sub
		iss: refresh_token.sub
		exp: params.expiration
	)
	signed_token := token.sign(auth.access_secret)
	return signed_token
}

fn (mut auth Tokens) authenticate_refresh_token(token SignedJWT) !bool {
	if !token.verify(auth.refresh_secret)! {
		auth.logger.debug('Session authenticator: Failed to verify signature of refresh token')
		return false
	}
	decoded_token := token.decode() or {
		panic('Session authenticator: Failed to decode token:\n ${err}')
	}
	if decoded_token.is_expired() {
		auth.logger.debug('Session authenticator: Refresh token has expired')
		return false
	}
	// if !auth.backend.session_exists(decoded_token.sub) {
	// 	auth.logger.debug('Session authenticator: Session id not found.')
	// 	return false
	// }
	return true
}

// authenticate_access_token authenticates an access token and
// verifies that the session which issued the token is still valid
pub fn (mut auth Tokens) authenticate_access_token(token SignedJWT) ! {
	decoded_token1 := token.decode() or {
		panic('Session authenticator: Failed to decode access token:\n ${err}')
	}
	auth.logger.debug('Authenticating access token: ${token}')
	if !token.verify(auth.access_secret)! {
		auth.logger.info('Failed to verify access token')
		return error('Failed to verify access token')
	}
	decoded_token := token.decode() or {
		panic('Session authenticator: Failed to decode access token:\n ${err}')
	}

	// the issuer of an access token is the session id of the
	// refresh token that issued the access token
	// if !auth.backend.session_exists(decoded_token.iss) {
	// 	auth.logger.debug("Session authenticator: session doesn't exist.")
	// 	return error('session doesnt exist')
	// }
}

pub fn (mut auth Tokens) revoke_refresh_token(token SignedJWT) ! {
	auth.authenticate_refresh_token(token)!
	// auth.backend.delete_session('${token.decode_subject()!}')
}
