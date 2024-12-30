module specification

import freeflowuniverse.crystallib.core.codemodel { Struct, Function }
import freeflowuniverse.crystallib.data.jsonschema { Schema, SchemaRef }
import freeflowuniverse.crystallib.web.openapi { Operation, Parameter, OpenAPI, Components, Info, PathItem, ServerSpec }
import freeflowuniverse.crystallib.rpc.openrpc { ContentDescriptor, Error }

// Helper function: Convert OpenAPI parameter to ContentDescriptor
fn openapi_param_to_content_descriptor(param Parameter) ContentDescriptor {
	return ContentDescriptor{
		name: param.name,
		summary: param.description,
		description: param.description,
		required: param.required,
		schema: param.schema
	}
}

// Helper function: Convert OpenAPI operation to ActorMethod
fn openapi_operation_to_actor_method(op Operation, method_name string, path string) ActorMethod {
	mut parameters := []ContentDescriptor{}
	for param in op.parameters {
		parameters << openapi_param_to_content_descriptor(param)
	}

	mut result := ContentDescriptor{
		name: "result",
		description: "The response of the operation.",
		required: true,
		schema: op.responses['200'].content['application/json'].schema
	}

	mut errors := []Error{}
	for status, response in op.responses {
		if status.int() >= 400 {
			error_schema := if response.content.len > 0 {
				response.content.values()[0].schema
			} else {Schema{}}
			errors << Error{
				code: status.int(),
				message: response.description,
				data: error_schema, // Extend if error schema is defined
			}
		}
	}

	return ActorMethod{
		name: method_name,
		description: op.description,
		summary: op.summary,
		parameters: parameters,
		result: result,
		errors: errors,
	}
}

// Helper function: Convert OpenAPI schema to Struct
fn openapi_schema_to_struct(name string, schema SchemaRef) Struct {
	// Assuming schema properties can be mapped to Struct fields
	return Struct{
		name: name,
	}
}

// Converts OpenAPI to ActorSpecification
pub fn from_openapi(spec OpenAPI) !ActorSpecification {
	mut methods := []ActorMethod{}
	mut objects := []BaseObject{}

	// Extract methods from OpenAPI paths
	for path, item in spec.paths {
		if item.get.operation_id != '' {
			methods << openapi_operation_to_actor_method(item.get, item.get.operation_id, path)
		}
		if item.post.operation_id != '' {
			methods << openapi_operation_to_actor_method(item.post, item.post.operation_id, path)
		}
		if item.put.operation_id != '' {
			methods << openapi_operation_to_actor_method(item.put, item.put.operation_id, path)
		}
		if item.delete.operation_id != '' {
			methods << openapi_operation_to_actor_method(item.delete, item.delete.operation_id, path)
		}
		if item.patch.operation_id != '' {
			methods << openapi_operation_to_actor_method(item.patch, item.patch.operation_id, path)
		}
		if item.head.operation_id != '' {
			methods << openapi_operation_to_actor_method(item.head, item.head.operation_id, path)
		}
		if item.options.operation_id != '' {
			methods << openapi_operation_to_actor_method(item.options, item.options.operation_id, path)
		}
		if item.trace.operation_id != '' {
			methods << openapi_operation_to_actor_method(item.trace, item.trace.operation_id, path)
		}
	}

	// Extract objects from OpenAPI components.schemas
	for name, schema in spec.components.schemas {
		objects << BaseObject{
			structure: openapi_schema_to_struct(name, schema),
			methods: []Function{}, // Add related methods if applicable
			children: []Struct{},  // Add nested structures if defined
		}
	}

	return ActorSpecification{
		name: spec.info.title,
		description: spec.info.description,
		structure: Struct{}, // Assuming no top-level structure for this use case
		interfaces: [.openapi], // Default to OpenAPI for input
		methods: methods,
		objects: objects,
	}
}