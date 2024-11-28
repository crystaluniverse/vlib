module email

import net.http
import time
import json

// session controller that be be added to vweb projects
pub struct EmailClient {
	url string @[required]
}

struct PostParams {
	url     string
	data    string
	timeout time.Duration
}

fn (client EmailClient) post_request(params PostParams) !http.Response {
	mut req := http.new_request(http.Method.post, params.url, params.data)
	req.read_timeout = params.timeout
	resp := req.do() or {
		return error('Failed to send request to email authentication server: ${err.code}')
	}
	if resp.status_code == 404 {
		return error('Could not find email verification endpoint, please make sure the auth client url is configured to the url the auth server is running at.')
	}
	if resp.status_code != 200 {
		panic('Email verification request failed, this should never happen: ${resp.status_msg}')
	}
	return resp
}

// verify_email posts an email verification req to the email auth controller
pub fn (client EmailClient) email_authentication(params SendMailConfig) ! {
	client.post_request(
		url: '${client.url}/email_authentication'
		data: json.encode(params)
		timeout: 180 * time.second
	)!
}

// verify_email posts an email verification req to the email auth controller
pub fn (client EmailClient) is_verified(address string) !bool {
	resp := client.post_request(
		url: '${client.url}/is_verified'
		data: json.encode(address)
		timeout: 180 * time.second
	)!
	return resp.body == 'true'
}

// send_verification_email posts an email verification req to the email auth controller
pub fn (client EmailClient) send_verification_email(params SendMailConfig) ! {
	client.post_request(
		url: '${client.url}/send_verification_mail'
		data: json.encode(params)
	) or { return error(err.msg()) }
}

// authenticate posts an authentication attempt req to the email auth controller
pub fn (c EmailClient) authenticate(address string, cypher string) !AttemptResult {
	resp := http.post('${c.url}/authenticate', json.encode(AuthAttempt{
		address: address
		cypher: cypher
	}))!
	result := json.decode(AttemptResult, resp.body)!
	return result
}
