module generator

import freeflowuniverse.crystallib.core.codemodel { Folder, IFile, VFile, CodeItem, File, Function, Import, Module, Struct, CustomCode }
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.core.codeparser
import freeflowuniverse.crystallib.data.markdownparser
import freeflowuniverse.crystallib.data.markdownparser.elements { Header }
import freeflowuniverse.crystallib.rpc.openrpc
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.hero.baobab.specification {ActorMethod, ActorSpecification}
import os
import json

fn generate_handle_file(spec ActorSpecification) !VFile {
	mut items := []CodeItem{}
	items << CustomCode{generate_handle_function(spec)}
	for i in spec.methods {
		println(generate_method_handle(i)!)
		items << CustomCode{generate_method_handle(i)!}
	}
	items << spec.methods.map(generate_method_handle(it)!).map(CustomCode{it})
	return VFile {
		name: 'handle'
		items: items
	}
}

pub fn generate_handle_function(spec ActorSpecification) string {
	mut operation_handlers := []string{}
	mut routes := []string{}

	// Iterate over OpenAPI paths and operations
	for method in spec.methods {
			operation_id := method.name
			params := method.func.params.map(it.name).join(', ')

			// Generate route case
			route := generate_route_case(method.name, operation_id)
			routes << route
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
		'pub fn (mut h OpenAPIHandler) handle(req Request) !Response {',
		'    match req.operation.operation_id {',
		routes.join('\n'),
		'        else {',
		'            return error("Unknown operation: \${req.operation.operation_id}")',
		'        }',
		'    }',
		'}',
	].join('\n')
}

pub fn generate_method_handle(method ActorMethod) !string {
	name_fixed := texttools.name_fix_snake(method.name)
	mut handler := '// Handler for ${name_fixed}\n'
	handler += "fn (mut actor Actor) handle_${name_fixed}(data string) !string {\n"
	if method.func.params.len > 0 {
		handler += '    params := json.decode(${method.func.params[0].typ.symbol}, data) or { return error("Invalid input data: \${err}") }\n'
		handler += '    result := actor.${name_fixed}(params)\n'
	} else {
		handler += '    result := actor.${name_fixed}()\n'
	}
	handler += '    return json.encode(result)\n'
	handler += '}'
	return handler
}

// Helper function to generate a case block for the main router
fn generate_route_case(method string, operation_id string) string {
	name_fixed := texttools.name_fix_snake(operation_id)
	mut case_block := '        "${operation_id}" {'
	case_block += '\n            response := h.actor.handle_${name_fixed}(req.body) or {'
	case_block += '\n                return Response{ status: http.Status.internal_server_error, body: "Internal server error: \${err}" }'
	case_block += '\n            }'
	case_block += '\n            return Response{ status: http.Status.ok, body: response }'
	case_block += '\n        }'
	return case_block
}