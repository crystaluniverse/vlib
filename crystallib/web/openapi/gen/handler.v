module generation

import freeflowuniverse.crystallib.web.openapi {OpenAPI}

pub fn openapi_to_handler_file(spec OpenAPI) string {
	mut operation_handlers := []string{}
	mut routes := []string{}

	// Iterate over OpenAPI paths and operations
	for path, path_item in spec.paths {
		for method_name, operation in path_item.methods {
			if operation is openapi.Operation {
				operation_id := operation.operation_id
				params := operation.parameters.map(it.name).join(', ')
				
				// Generate individual handler
				handler := generate_individual_handler(method_name, operation_id, params)
				operation_handlers << handler

				// Generate route case
				route := generate_route_case(method_name, path, operation_id)
				routes << route
			}
		}
	}

	// Combine the generated handlers and main router into a single file
	return [
		'// AUTO-GENERATED FILE - DO NOT EDIT MANUALLY',
		'',
		'pub struct OpenAPIHandler {',
		'    mut:',
		'        actor Actor',
		'}',
		'',
		operation_handlers.join('\n\n'),
		'',
		'pub fn (mut h OpenAPIHandler) handle(req Request) !Response {',
		'    match req.operation.operation_id {',
		routes.join('\n'),
		'        else {',
		'            return error("Unknown operation: ${req.operation.operation_id}")',
		'        }',
		'    }',
		'}',
	].join('\n')
}

// Helper function to generate individual handlers
fn generate_individual_handler(method string, operation_id string, params string) string {
	mut handler := '// Handler for $operation_id\n'
	handler += "fn (mut actor Actor) handle_$operation_id(data string) !string {\n"
	handler += "    println('Handling $operation_id with data: \$data')\n"
	if params.len > 0 {
		handler += '    params := json.decode($params, data) or { return error("Invalid input data: \$err") }\n'
		handler += '    result := actor.data_store.$operation_id(params)\n'
	} else {
		handler += '    result := actor.data_store.$operation_id()\n'
	}
	handler += '    return json.encode(result)\n'
	handler += '}'
	return handler
}

// Helper function to generate a case block for the main router
fn generate_route_case(method string, path string, operation_id string) string {
	mut case_block := '        "$operation_id" {'
	case_block += '\n            println("Handling $operation_id for $method $path")'
	case_block += '\n            response := h.actor.handle_$operation_id(req.body) or {'
	case_block += '\n                return Response{ status: http.Status.internal_server_error, body: "Internal server error: $err" }'
	case_block += '\n            }'
	case_block += '\n            return Response{ status: http.Status.ok, body: response }'
	case_block += '\n        }'
	return case_block
}