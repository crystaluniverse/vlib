module actor

import veb
import freeflowuniverse.crystallib.web.openapi { Context, Controller, OpenAPI, Request, Response }
import freeflowuniverse.crystallib.hero.baobab.rpc { ProcedureError }
import os
import time
import json
import x.json2
import net.http
import freeflowuniverse.crystallib.data.jsonschema
// import freeflowuniverse.crystallib.hero.processor {Processor, ProcedureCall, ProcedureResponse, ProcessParams}
import freeflowuniverse.crystallib.clients.redisclient

pub struct OpenAPIProxy {
	client        Client
	specification OpenAPI
}

// creates and OpenAPI Proxy Controller
pub fn new_openapi_proxy(proxy OpenAPIProxy) OpenAPIProxy {
	return proxy
}

// creates and OpenAPI Proxy Controller
pub fn (proxy OpenAPIProxy) controller() &Controller {
	// Initialize the server
	mut controller := &Controller{
		specification: proxy.specification
		handler:       Handler{
			client: proxy.client
		}
	}
	return controller
}

@[params]
pub struct RunParams {
pub:
	port int = 8080
}

fn (proxy OpenAPIProxy) run(params RunParams) {
	mut controller := proxy.controller()
	veb.run[Controller, Context](mut controller, params.port)
}

pub struct Handler {
pub mut:
	client Client
}

fn (mut handler Handler) handle(request Request) !Response {
	// Convert incoming OpenAPI request to a procedure call
	call := rpc.openapi_request_to_procedure_call(request)

	// Process the procedure call
	procedure_response := handler.client.dialogue(call, Params{
		timeout: 30 // Set timeout in seconds
	}) or {
		// Handle ProcedureError
		if err is ProcedureError {
			return Response{
				status: http.status_from_int(err.code()) // Map ProcedureError reason to HTTP status code
				body:   json.encode({
					'error': err.msg()
				})
			}
		}
		return error('Unexpected error: ${err}')
	}

	// Convert returned procedure response to OpenAPI response
	return Response{
		status: http.Status.ok // Assuming success if no error
		body:   procedure_response.result
	}
}
