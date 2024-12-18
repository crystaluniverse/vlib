module main

import json
import encoding.base64
import net.http

struct CustomResponse {
	status  int
	message string
}

fn (c CustomResponse) to_json() string {
	return json.encode(c)
}

const invalid_json = 'Invalid JSON Payload.'
const user_not_found = 'User not found.'
const user_unique = 'User with this username already exists.'
const invalid_user = 'Please make sure that you entered a valid username and password.'
const wrong_credential = 'Invalid credentials'
const no_signature = 'Make sure that you have an "Authorization" in your header.'

fn encode(username string, password string) string {
	return base64.encode('${username}:${password}'.bytes())
}

fn decode(signature string) string {
	mut sig := signature
	if signature.contains('Basic ') {
		sig = signature.split(' ')[1]
	}
	sig = base64.decode(sig).bytestr()
	return sig
}

fn basic_auth(users map[string]string, mut app App) ? {
	mut processed_users := map[string]string{}
	for u, p in users {
		encodedauth := base64.encode('${u}:${p}'.bytes())
		processed_users['Basic ${encodedauth}'] = u
	}
	headers_keys := app.Context.req.header.keys()
	mut value := ''
	if headers_keys.contains('Authorization') {
		value = app.Context.req.header.get_custom(headers_keys[headers_keys.index('Authorization')])?
	}
	if processed_users[value] == '' {
		app.set_status(403, wrong_credential)
		app.add_header('WWW-Authenticate', 'Basic realm="private"')
		er := CustomResponse{403, wrong_credential}
		app.json(er.to_json())
	}
}
