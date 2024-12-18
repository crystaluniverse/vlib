module openapi

import veb
import json
import freeflowuniverse.crystallib.data.jsonschema { Schema }
import x.json2 { Any }
import net.http

pub struct Server {
pub:
	specification OpenAPI
pub mut:
	handler IHandler
}

pub struct Context {
	veb.Context
}

// Matches a request path against OpenAPI path templates in the parsed structs
// Returns the matching path key and corresponding PathItem if found
fn match_path(req_path string, spec OpenAPI) !PathItem {
	// Iterate through all paths in the OpenAPI specification
	for template, path_item in spec.paths {
		if is_path_match(req_path, template) {
			// Return the matching path template and its PathItem
			return path_item
		}
	}
	// If no match is found, return an error
	return error('Path not found')
}

// Checks if a request path matches a given OpenAPI path template
// Allows for dynamic path segments like `{petId}` in templates
fn is_path_match(req_path string, template string) bool {
	// Split the request path and template into segments
	req_segments := req_path.split('/')
	template_segments := template.split('/')

	// If the number of segments doesn't match, the paths can't match
	if req_segments.len != template_segments.len {
		return false
	}

	// Compare each segment in the template and request path
	for i, segment in template_segments {
		// If the segment is not dynamic (doesn't start with `{`), ensure it matches exactly
		if !segment.starts_with('{') && segment != req_segments[i] {
			return false
		}
	}
	// If all segments match or dynamic segments are valid, return true
	return true
}

@['/:path...'; delete; get; patch; post; put]
pub fn (mut server Server) index(mut ctx Context, path string) veb.Result {
	println('Requested path: ${path}')

	// Extract the HTTP method
	method := ctx.req.method.str().to_lower()

	// Matches the request path against the OpenAPI specification and retrieves the corresponding PathItem
	path_item := match_path(path, server.specification) or {
		// Return a 404 error if no matching path is found
		return ctx.not_found()
	}

	// // Check if the path exists in the OpenAPI specification
	// path_item := server.specification.paths[path] or {
	//     // Return a 404 error if the path is not defined
	//     return ctx.not_found()
	// }

	// Match the HTTP method with the OpenAPI specification
	operation := match method {
		'get' {
			path_item.get
		}
		'post' {
			path_item.post
		}
		'put' {
			path_item.put
		}
		'delete' {
			path_item.delete
		}
		'patch' {
			path_item.patch
		}
		else {
			// Return 405 Method Not Allowed if the method is not supported
			return ctx.method_not_allowed()
		}
	}

	mut arg_map := map[string]Any{}
	path_arg := path.all_after_last('/')
	// the OpenAPI Parameter specification belonging to the path argument
	arg_params := operation.parameters.filter(it.in_ == 'path')
	if arg_params.len > 1 {
		// TODO: use path template to support multiple arguments (right now just last arg supported)
		panic('implement')
	} else if arg_params.len == 1 {
		arg_map[arg_params[0].name] = arg_params[0].typed(path_arg)
	}

	mut parameters := ctx.query.clone()
	// Build the Request object
	request := Request{
		path:       path
		operation:  operation
		method:     method
		arguments:  arg_map
		parameters: parameters
		body:       ctx.req.data
		header:     ctx.req.header
	}

	// Use the handler to process the request
	response := server.handler.handle(request) or {
		// Use OpenAPI spec to determine the response status for the error
		return ctx.handle_error(operation.responses, err)
	}

	// Return the response to the client
	ctx.res.set_status(response.status)

	// ctx.res.header = response.header
	// ctx.set_content_type('application/json')

	// return ctx.ok('[]')
	return ctx.send_response_to_client('application/json', response.body)
}

// Handles errors and maps them to OpenAPI-defined response statuses
fn (mut ctx Context) handle_error(possible_responses map[string]ResponseSpec, err IError) veb.Result {
	// Match the error with the defined responses
	for code, _ in possible_responses {
		if matches_error_to_status(err, code.int()) {
			ctx.res.set_status(http.status_from_int(code.int()))
			ctx.set_content_type('application/json')
			return ctx.send_response_to_client('application/json', '{"error": "${err.msg()}", "status": ${code}}')
		}
	}

	// Default to 500 Internal Server Error if no match is found
	ctx.res.set_status(.internal_server_error)
	ctx.set_content_type('application/json')
	return ctx.send_response_to_client('application/json', '{"error": "Internal Server Error", "status": 500}')
}

// Helper to match an error to a specific response status
fn matches_error_to_status(err IError, status int) bool {
	// This can be customized to map specific errors to statuses
	// For simplicity, we'll use a direct comparison here.
	return err.code() == status
}

// Helper for 405 Method Not Allowed response
fn (mut ctx Context) method_not_allowed() veb.Result {
	ctx.res.set_status(.method_not_allowed)
	ctx.set_content_type('application/json')
	return ctx.send_response_to_client('application/json', '{"error": "Method Not Allowed", "status": 405}')
}

pub fn (param Parameter) typed(value string) Any {
	param_schema := param.schema as Schema
	param_type := param_schema.typ
	param_format := param_schema.format

	// Convert parameter value to corresponding type
	typ := match param_type {
		'integer' {
			param_format
		}
		'number' {
			param_format
		}
		else {
			param_type // Leave as param type for unknown types
		}
	}
	return typed(value, typ)
}

// typed gets a value that is string and a desired type, and returns the typed string in Any Type.
pub fn typed(value string, typ string) Any {
	match typ {
		'int32' {
			return value.int() // Convert to int
		}
		'int64' {
			return value.i64() // Convert to i64
		}
		'string' {
			return value // Already a string
		}
		'boolean' {
			return value.bool() // Convert to bool
		}
		'float' {
			return value.f32() // Convert to float
		}
		'double' {
			return value.f64() // Convert to double
		}
		else {
			return value.f64() // Leave as string for unknown types
		}
	}
}
