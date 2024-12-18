module sendgrid

import net.http
import json

pub struct Client {
pub:
	token string
}

const send_api_endpoint = 'https://api.sendgrid.com/v3/mail/send'

pub fn new_client(token string) !Client {
	if token.len == 0 {
		return error('empty token')
	}

	return Client{
		token: token
	}
}

fn (c Client) get_headers() !http.Header {
	headers_map := {
		'Authorization': 'Bearer ${c.token}'
		'Content-Type':  'application/json'
	}
	headers := http.new_custom_header_from_map(headers_map)!

	return headers
}

pub fn (c Client) send(email Email) ! {
	mut request := http.new_request(http.Method.post, send_api_endpoint, json.encode(email))
	request.header = c.get_headers()!

	res := request.do()!
	if res.status_code != int(http.Status.accepted) {
		return error(res.body)
	}
}
