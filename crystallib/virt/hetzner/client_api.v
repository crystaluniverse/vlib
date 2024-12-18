module hetzner

import net.http
import freeflowuniverse.crystallib.ui.console

// TODO: it would have been better to use the crystallib httpclient

fn (mut h HetznerClient[Config]) request_get(endpoint string) !string {
	mut r := http.Request{
		url: h.config()!.baseurl + endpoint
	}

	r.add_header(http.CommonHeader.authorization, 'Basic ' + h.auth)
	response := r.do()!

	if response.status_code != 200 {
		return error('could not process request ${endpoint}: error ${response.status_code} \n${response.body}')
	}

	return response.body
}

fn (mut h HetznerClient[Config]) request_post(endpoint string, data string) !http.Response {
	console.print_debug('request post: ${endpoint}\n${data}')

	mut r := http.Request{
		method: .post
		data:   data
		url:    h.config()!.baseurl + endpoint
	}

	r.add_header(http.CommonHeader.authorization, 'Basic ' + h.auth)
	r.add_header(http.CommonHeader.content_type, 'application/x-www-form-urlencoded')
	response := r.do()!

	return response
}
