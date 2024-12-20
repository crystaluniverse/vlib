module actor

import freeflowuniverse.crystallib.web.openapi { OpenAPI }
import veb

pub struct Server {
	veb.Controller
}

pub struct Context {
	veb.Context
}

pub struct ServerConfig {
	ClientConfig
pub:
	openapi_spec OpenAPI
}

pub fn new_server(cfg ServerConfig) !&Server {
	mut s := &Server{}

	openapi_proxy := new_openapi_proxy(
		client:        new_client(cfg.ClientConfig)!
		specification: cfg.openapi_spec
	)

	s.register_controller[openapi.Controller, Context]('/openapi', mut openapi_proxy.controller())!
	return s
}

pub fn (mut server Server) run(params RunParams) {
	veb.run[Server, Context](mut server, params.port)
}
