module generator

import json
import freeflowuniverse.crystallib.core.codemodel { VFile, File, Function, Module, Struct }
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.hero.baobab.specification {ActorSpecification}
import freeflowuniverse.crystallib.rpc.openrpc { Components, OpenRPC }
import freeflowuniverse.crystallib.data.jsonschema { SchemaRef }

pub fn generate_openrpc_file(spec OpenRPC) !File {
	return File {
		name: 'openrpc'
		extension: 'json'
		content: json.encode(spec)
	}	
}

pub fn generate_openrpc_client_file(spec OpenRPC) !VFile {
	mut objects_map := map[string]Struct{}
	// for object in spec.objects {
	// 	objects_map[object.structure.name] = object.structure
	// }
	client_file := spec.generate_client_file(objects_map)!
	return VFile {
		...client_file,
		name: 'client_openrpc'
	}	
}
	
pub fn generate_openrpc_client_test_file(spec OpenRPC) !VFile {
	mut objects_map := map[string]Struct{}
	// for object in spec.objects {
	// 	objects_map[object.structure.name] = object.structure
	// }
	mut methods_map := map[string]Function{}
	// for method in spec.methods {
	// 	methods_map[method.func.name] = method.func
	// }
	file := spec.generate_client_test_file(methods_map, objects_map)!
	return VFile {
		...file,
		name: 'client_openrpc_test'
	}	
}

// pub fn (actor Actor) generate_openrpc_code() !Module {
// 	openrpc_obj := actor.generate_openrpc()
// 	openrpc_json := openrpc_obj.encode()!

// 	openrpc_file := File{
// 		name: 'openrpc'
// 		extension: 'json'
// 		content: openrpc_json
// 	}

// 	mut methods_map := map[string]Function{}
// 	for method in actor.methods {
// 		methods_map[method.func.name] = method.func
// 	}

// 	mut objects_map := map[string]Struct{}
// 	for object in actor.objects {
// 		objects_map[object.structure.name] = object.structure
// 	}
// 	// actor_struct := generate_actor_struct(actor.name)
// 	actor_struct := actor.structure

// 	client_file := openrpc_obj.generate_client_file(objects_map)!
// 	client_test_file := openrpc_obj.generate_client_test_file(methods_map, objects_map)!

// 	handler_file := openrpc_obj.generate_handler_file(actor_struct, methods_map, objects_map)!
// 	handler_test_file := openrpc_obj.generate_handler_test_file(actor_struct, methods_map,
// 		objects_map)!

// 	server_file := openrpc_obj.generate_server_file()!
// 	server_test_file := openrpc_obj.generate_server_test_file()!

// 	return Module{
// 		files: [
// 			client_file,
// 			client_test_file,
// 			handler_file,
// 			handler_test_file,
// 			server_file,
// 			server_test_file,
// 		]
// 		// misc_files: [openrpc_file]
// 	}
// }


// pub fn (mut a Actor) export_playground(path string, openrpc_path string) ! {
// 	dollar := '$'
// 	openrpc.export_playground(
// 		dest: pathlib.get_dir(path: '${path}/playground')!
// 		specs: [
// 			pathlib.get(openrpc_path),
// 		]
// 	)!
// 	mut cli_file := pathlib.get_file(path: '${path}/command/cli.v')!
// 	cli_file.write($tmpl('./templates/playground.v.template'))!
// }

// pub fn param_to_content_descriptor(param Param) openrpc.ContentDescriptor {
// 	if param.name == 'id' && param.typ.symbol ==

// 	return openrpc.ContentDescriptor {
// 		name: param.name
// 		summary: param.description
// 		required: param.is_required()
// 		schema:
// 	}
// }
