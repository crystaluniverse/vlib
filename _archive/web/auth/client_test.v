module auth

import vweb
import time
import net
import net.http

const server_url = 'http://localhost:8080'
const atimeout = 500 * time.millisecond

__global client Client

pub struct EchoHandler {
	vweb.Context
}

fn (h EchoHandler) handle(req http.Request) http.Response {
	mut resp := http.Response{
		body:   req.data
		header: req.header
	}
	resp.set_status(.ok)
	resp.set_version(req.version)
	return resp
}

fn testsuite_begin() {
	client = Client{
		url: server_url
	}
	mut server := &http.Server{
		accept_timeout:       atimeout
		handler:              EchoHandler{}
		show_startup_message: false
	}
	t := spawn server.listen_and_serve()
}

pub fn test_authorize() ! {
	authorized := client.authorize(
		asset_id:     'test_asset'
		access_type:  .read
		access_token: ''
	)!
}
