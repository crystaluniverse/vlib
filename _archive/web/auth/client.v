module auth

import net.http
import json
import time
import freeflowuniverse.crystallib.web.auth.identity
import freeflowuniverse.crystallib.web.auth.tokens
import freeflowuniverse.crystallib.web.auth.authorization
import freeflowuniverse.crystallib.web.auth.session
import freeflowuniverse.crystallib.web.auth.jwt

// // session controller that be be added to vweb projects
pub struct Client {
	url string @[required]
mut:
	identity      identity.Client
	tokens        tokens.Tokens
	session       session.Client
	authorization authorization.Client
}

pub struct ClientConfig {
	url string
}

pub fn new_client(config ClientConfig) Client {
	return Client{
		url: config.url
		identity: identity.Client{
			url: '${config.url}/identity'
		}
		session: session.Client{
			url: '${config.url}/session'
		}
	}
}

struct PostParams {
	url     string
	data    string
	timeout time.Duration
}

fn (client Client) post_request(params PostParams) !http.Response {
	mut req := http.new_request(http.Method.post, params.url, params.data)
	req.read_timeout = params.timeout
	resp := req.do() or {
		return error('Failed to send request to session authentication server: ${err.code}')
	}
	if resp.status_code == 404 {
		return error('Could not find session authentication endpoint, please make sure the auth client url is configured to the url the auth server is running at.')
	}
	if resp.status_code != 200 {
		panic('Session authentication request failed, this should never happen: ${resp.status_msg}')
	}
	return resp
}

pub fn (mut c Client) authorize(params AuthorizeParams) !bool {
	// TODO: beautify
	c.tokens.authenticate_access_token(params.access_token)!
	decoded := jwt.SignedJWT(params.access_token).decode()!
	sesh := c.session.get_session(decoded.sub)!
	user := c.identity.get_user(id: sesh.user_id)!
	return c.authorization.authorize(accessor: user.id)!
}

pub fn (c Client) assign_admin(user identity.User) ! {
	if !c.identity.user_exists(user)! {
		return error('user doesnt exist')
	}
	c.authorization.add_admin(user.id)!
}

pub fn (c Client) create_group(group identity.Group) ! {
	c.identity.create_group(group)!
}

pub fn (mut c Client) register(user identity.User) !string {
	return c.identity.register(user)!
}

// pub fn (client Client) new_auth_tokens(params RefreshTokenParams) !AuthTokens {
// 	resp := client.post_request(
// 		url: '${client.url}/new_auth_tokens'
// 		data: json.encode(params)
// 	) or { panic(err) }
// 	tokens := json.decode(AuthTokens, resp.body) or { panic('This should never happen ${err}') }
// 	return tokens
// }

// pub fn (c Client) new_refresh_token(params RefreshTokenParams) !string {
// 	resp := http.post('${c.url}/new_refresh_token', json.encode(params))!
// 	// todo response error check
// 	token := resp.body.trim('"')
// 	return token
// }

// pub fn (c Client) new_access_token(params AccessTokenParams) !string {
// 	resp := http.post('${c.url}/new_access_token', json.encode(params))!
// 	// todo response error check
// 	token := resp.body.trim('"')
// 	return token
// }

// pub fn (c Client) authenticate_access_token(access_token string) ! {
// 	url := '${c.url}/authenticate_access_token'
// 	resp := http.post(url, access_token) or { panic('this should never happen ${err}') }
// 	if resp.status_code != 200 {
// 		return error(resp.body)
// 	}
// }

// pub fn (c Client) get_token_subject(access_token string) !string {
// 	c.authenticate_access_token(access_token) or { return error(err.msg()) }
// 	return jwt.SignedJWT(access_token).decode_subject() or { panic(err) }
// }
