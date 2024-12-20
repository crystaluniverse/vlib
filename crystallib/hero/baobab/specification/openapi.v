module specification

import freeflowuniverse.crystallib.web.openapi { OpenAPI, Info, ServerSpec, Components, Operation, PathItem, PathRef, Parameter }
import freeflowuniverse.crystallib.core.codemodel { Struct, Function, Param }
import freeflowuniverse.crystallib.data.jsonschema { SchemaRef }

// Helper function: Convert OpenAPI parameter to codemodel Param
fn openapi_param_to_param(param Parameter) Param {
	return Param{
		name: param.name,
		typ: param.schema.to_code() or {panic(err)}, // Assuming the schema defines the parameter type
		required: param.required,
		description: param.description,
	}
}

// Helper function: Convert OpenAPI operation to codemodel Function
fn openapi_operation_to_function(op Operation, method_name string, path string) Function {
	mut params := []Param{}
	for param in op.parameters {
		params << openapi_param_to_param(param)
	}

	return Function{
		name: method_name,
		params: params,
		// receiver.mutable: op.request_body != none, // POST, PUT, etc., generally imply mutable operations
		description: op.description,
	}
}

// Helper function: Convert OpenAPI schema to codemodel Struct
fn openapi_schema_to_struct(name string, schema SchemaRef) Struct {
	return Struct{
		name: name,
		// Add field mapping if schema properties are available
	}
}

// Converts OpenAPI to ActorSpecification
pub fn from_openapi(spec OpenAPI) !ActorSpecification {
	mut methods := []ActorMethod{}
	mut objects := []BaseObject{}

// Extract methods from OpenAPI paths
for path, item in spec.paths {
	if item.get.operation_id != '' {
		methods << ActorMethod{
			name: item.get.operation_id,
			description: item.get.summary,
			func: openapi_operation_to_function(item.get, item.get.operation_id, path),
		}
	}
	if item.post.operation_id != '' {
		methods << ActorMethod{
			name: item.post.operation_id,
			description: item.post.summary,
			func: openapi_operation_to_function(item.post, item.post.operation_id, path),
		}
	}
	if item.put.operation_id != '' {
		methods << ActorMethod{
			name: item.put.operation_id,
			description: item.put.summary,
			func: openapi_operation_to_function(item.put, item.put.operation_id, path),
		}
	}
	if item.delete.operation_id != '' {
		methods << ActorMethod{
			name: item.delete.operation_id,
			description: item.delete.summary,
			func: openapi_operation_to_function(item.delete, item.delete.operation_id, path),
		}
	}
	if item.patch.operation_id != '' {
		methods << ActorMethod{
			name: item.patch.operation_id,
			description: item.patch.summary,
			func: openapi_operation_to_function(item.patch, item.patch.operation_id, path),
		}
	}
	if item.head.operation_id != '' {
		methods << ActorMethod{
			name: item.head.operation_id,
			description: item.head.summary,
			func: openapi_operation_to_function(item.head, item.head.operation_id, path),
		}
	}
	if item.options.operation_id != '' {
		methods << ActorMethod{
			name: item.options.operation_id,
			description: item.options.summary,
			func: openapi_operation_to_function(item.options, item.options.operation_id, path),
		}
	}
	if item.trace.operation_id != '' {
		methods << ActorMethod{
			name: item.trace.operation_id,
			description: item.trace.summary,
			func: openapi_operation_to_function(item.trace, item.trace.operation_id, path),
		}
	}
}
	// Extract objects from OpenAPI components.schemas
	for name, schema in spec.components.schemas {
		objects << BaseObject{
			structure: openapi_schema_to_struct(name, schema),
			methods: []Function{}, // Add related methods if applicable
			children: []Struct{},  // Add children if schemas define nested structures
		}
	}

	return ActorSpecification{
		name: spec.info.title,
		description: spec.info.description,
		methods: methods,
		objects: objects,
	}
}

// Converts ActorSpecification to OpenAPI
pub fn (s ActorSpecification) to_openapi() OpenAPI {
	mut paths := map[string]PathItem{}

	// Map ActorMethods to paths
	for method in s.methods {
		mut op := Operation{
			summary: method.description,
			operation_id: method.name,
		}

		// Set parameters and other fields based on the codemodel Function
		for param in method.func.params {
			op.parameters << Parameter{
				name: param.name,
				in_: 'query', // Default location; adjust based on actual function context
				description: param.description,
				required: param.required,
				schema: jsonschema.param_to_schema(param)
			}
		}

		// Assign operation to corresponding HTTP method
		if method.func.receiver.mutable {
			paths['/${method.name}'] = PathItem{post: op}
		} else {
			paths['/${method.name}'] = PathItem{get: op}
		}
	}

	return OpenAPI{
		openapi: '3.0.0',
		info: Info{
			title: s.name,
			summary: s.description,
			description: s.description,
			version: '1.0.0',
		},
		servers: [
			ServerSpec{
				url: 'http://localhost:8080',
				description: 'Default server',
			},
		],
		paths: paths,
		components: Components{
			// Assuming the `objects` in ActorSpecification can be converted to schemas
			// schemas: s.objects.map(it.structure.name => SchemaRef{name: it.structure.name}),
		},
	}
}