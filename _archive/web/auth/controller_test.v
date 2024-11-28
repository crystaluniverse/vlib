module auth

import vweb
import net.http
import freeflowuniverse.crystallib.web.auth.email
import toml
import os
import json
import freeflowuniverse.crystallib.ui.console

const server_url = 'http://localhost:8091'

fn testsuite_begin() {
	controller := configure_controller()!
	spawn vweb.run_at(&controller, port: 8091, nr_workers: 1)
}

fn configure_controller() !AuthServer {
	env := toml.parse_file(os.dir(@FILE) + '/.env') or { panic('Could not find .env, ${err}') }

	return new_server(
		smtp: email.SmtpConfig{
			server: env.value('SMTP_SERVER').string()
			from: 'verify@authenticator.io'
			port: env.value('SMTP_PORT').int()
			username: env.value('SMTP_USERNAME').string()
			password: env.value('SMTP_PASSWORD').string()
		}
	)!
}

fn test_register() {
	// controller := configure_controller()!
	// spawn vweb.run(&controller, 8091)
	console.print_debug('registering1')
	req := http.new_request(.post, '${auth.server_url}/register', 'test@email.com')
	resp := req.do()!

	registration := json.decode(Registration, resp.body)!
	assert registration.user.id != ''
	assert registration.user.email == 'test@email.com'
	assert registration.tokens.access_token != ''
	assert registration.tokens.refresh_token != ''
}

fn test_authenticate() {
	// controller := configure_controller()!
	// spawn vweb.run(&controller, 8092)
	console.print_debug('registering2')

	req0 := http.new_request(.post, '${auth.server_url}/register', 'test@email2.com')
	resp0 := req0.do()!
	registration := json.decode(Registration, resp0.body)!

	mut req1 := http.new_request(.post, '${auth.server_url}/authenticate', '')
	req1.add_cookie(
		name: 'access_token'
		value: registration.tokens.access_token
	)
	req1.add_cookie(
		name: 'refresh_token'
		value: registration.tokens.refresh_token
	)
	resp1 := req1.do()!
	console.print_debug('resp: ${resp1}')
	panic('s ')
}
