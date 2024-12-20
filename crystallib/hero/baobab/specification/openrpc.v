module specification

import freeflowuniverse.crystallib.rpc.openrpc {OpenRPC}
import freeflowuniverse.crystallib.web.openapi {OpenAPI}

pub fn from_openrpc(spec openrpc.OpenRPC) !ActorSpecification {
	// Extract Actor metadata from OpenRPC info
	// actor_name := openrpc_doc.info.title
	// actor_description := openrpc_doc.info.description

	// // Generate methods
	// mut methods := []ActorMethod{}
	// for method in openrpc_doc.methods {
	// 	method_code := method.to_code()! // Using provided to_code function
	// 	methods << ActorMethod{
	// 		name: method.name
	// 		func: method_code
	// 	}
	// }

	// // Generate BaseObject structs from schemas
	// mut objects := []BaseObject{}
	// for key, schema_ref in openrpc_doc.components.schemas {
	// 	struct_obj := schema_ref.to_code()! // Assuming schema_ref.to_code() converts schema to Struct
	// 	// objects << BaseObject{
	// 	// 	structure: codemodel.Struct{
	// 	// 		name: struct_obj.name
	// 	// 	}
	// 	// }
	// }

	// Build the Actor struct
	return ActorSpecification{
		// name: actor_name
		// description: actor_description
		// methods: methods
		// objects: objects
	}
}


pub fn (s ActorSpecification) to_openrpc() OpenRPC {
	return OpenRPC {

	}
}