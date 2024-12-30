module specification

import freeflowuniverse.crystallib.rpc.openrpc { OpenRPC, Method, ContentDescriptor, Error }
import freeflowuniverse.crystallib.core.codemodel { Struct, Function }
import freeflowuniverse.crystallib.data.jsonschema { Schema, SchemaRef }

// Helper function: Convert OpenRPC Method to ActorMethod
fn openrpc_method_to_actor_method(method Method) ActorMethod {
	mut parameters := []ContentDescriptor{}
	mut errors := []Error{}

	// Process parameters
	for param in method.params {
		parameters << param
	}

	// Process errors
	for err in method.errors {
		errors << err
	}

	// Process result
	result := method.result or {
		ContentDescriptor{
			name: "result"
			description: "The default result of the method."
			required: true
			schema: SchemaRef{} // Fallback empty schema if not provided
		}
	}

	return ActorMethod{
		name: method.name
		description: method.description
		summary: method.summary
		parameters: parameters
		result: result
		errors: errors
	}
}

// Helper function: Extract Structs from OpenRPC Components
fn extract_structs_from_openrpc(openrpc OpenRPC) []Struct {
	mut structs := []Struct{}

	for schema_name, schema in openrpc.components.schemas {
		mut fields := []Struct.Field{}
		for field_name, field_schema in schema.properties {
			fields << Struct.Field{
				name: field_name
				typ: field_schema.to_code() or { panic(err) }
				description: field_schema.description
				required: field_name in schema.required
			}
		}

		structs << Struct{
			name: schema_name
			description: schema.description
			fields: fields
		}
	}

	return structs
}

// Converts OpenRPC to ActorSpecification
pub fn from_openrpc(spec OpenRPC) !ActorSpecification {
	mut methods := []ActorMethod{}
	mut objects := []BaseObject{}

	// Process methods
	for method in spec.methods {
		methods << openrpc_method_to_actor_method(method)
	}

	// Process objects (schemas)
	structs := extract_structs_from_openrpc(spec)
	for structure in structs {
		objects << BaseObject{
			structure: structure
		}
	}

	return ActorSpecification{
		name: spec.info.title
		description: spec.info.description
		interfaces: [.openrpc]
		methods: methods
		objects: objects
	}
}