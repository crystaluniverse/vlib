module generator

import freeflowuniverse.crystallib.core.codemodel { Folder, VFile, CodeItem, File, Function, Import, Module, Struct, CustomCode }
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.core.codeparser
import freeflowuniverse.crystallib.data.markdownparser
import freeflowuniverse.crystallib.data.markdownparser.elements { Header }
import freeflowuniverse.crystallib.rpc.openrpc
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.hero.baobab.specification {ActorMethod, ActorSpecification}
import os
import json

pub fn generate_actor_module(spec ActorSpecification) !Module {
	return Module {
		name: '${spec.name}_actor'
		files: [
			generate_readme_file(spec)!,
			generate_handle_file(spec)!
		]
		folders: [
			generate_docs_folder(spec)!
		]
	}
}

pub fn generate_readme_file(spec ActorSpecification) !File {
	return File{
		name: 'README'
		extension: 'md'
		content: '# ${spec.name}\n${spec.description}'
	}
}

pub fn generate_handle_file(spec ActorSpecification) !VFile {
	mut items := []CodeItem{}
	items << CustomCode{generate_handle_function(spec)}
	items << spec.methods.map(generate_method_handle(it)!).map(CustomCode{it})
	return VFile {
		name: 'handle'
		items: items
	}
}

pub fn generate_docs_folder(spec ActorSpecification) !Folder {
	return Folder {
		name: 'docs'
		files: [
			generate_openrpc_file(spec)!,
			generate_openapi_file(spec)!
		]
	}
}

pub fn generate_openrpc_file(spec ActorSpecification) !File {
	openrpc_spec := spec.to_openrpc()
	openrpc_json := openrpc_spec.encode()!
	return File{
		name: 'openrpc'
		extension: 'json'
		content: openrpc_json
	}
}

pub fn generate_openapi_file(spec ActorSpecification) !File {
	openapi_spec := spec.to_openapi()
	openapi_json := json.encode(openapi_spec)
	return File{
		name: 'openapi'
		extension: 'json'
		content: openapi_json
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
	mut handler := '// Handler for ${method.name}\n'
	handler += "fn (mut actor Actor) handle_${method.name}(data string) !string {\n"
	handler += "    println('Handling ${method.name} with data: \$data')\n"

	if method.func.params.len > 0 {
		handler += '    params := json.decode(${method.func.params[0].typ.symbol}, data) or { return error("Invalid input data: \${err}") }\n'
		handler += '    result := actor.data_store.${method.name}(params)\n'
	} else {
		handler += '    result := actor.data_store.${method.name}()\n'
	}
	handler += '    return json.encode(result)\n'
	handler += '}'
	return handler
}

// Helper function to generate a case block for the main router
fn generate_route_case(method string, operation_id string) string {
	mut case_block := '        "${operation_id}" {'
	case_block += '\n            println("Handling $operation_id for ${method}")'
	case_block += '\n            response := h.actor.handle_${operation_id}(req.body) or {'
	case_block += '\n                return Response{ status: http.Status.internal_server_error, body: "Internal server error: \$err" }'
	case_block += '\n            }'
	case_block += '\n            return Response{ status: http.Status.ok, body: response }'
	case_block += '\n        }'
	return case_block
}

// pub fn (actor Actor) generate_methods() ![]ActorMethod {
// 	mut methods := []ActorMethod{}
// 	for object in actor.objects {
// 		methods << [
// 			ActorMethod{
// 				name: object.structure.name
// 				func: generate_new_method(actor.structure, object)
// 			},
// 			ActorMethod{
// 				name: object.structure.name
// 				func: generate_get_method(actor.structure, object)
// 			},
// 			ActorMethod{
// 				name: object.structure.name
// 				func: generate_set_method(actor.structure, object)
// 			},
// 			ActorMethod{
// 				name: object.structure.name
// 				func: generate_delete_method(actor.structure, object)
// 			},
// 			ActorMethod{
// 				name: object.structure.name
// 				func: generate_list_method(actor.structure, object)
// 			},
// 		]
// 	}
// 	return methods
// }

// pub struct ActorConfig {
// pub mut:
// 	name string
// }

// pub fn parse_actor(path string) !Actor {
// 	code := codeparser.parse_v(path, recursive: true)!
// 	mut config := parse_config('${path}/config.json')!

// 	mut methods := []ActorMethod{}
// 	for s in code.filter(it is Function).map(it as Function).filter(it.receiver.name == config.name) {
// 		methods << ActorMethod{
// 			func: s
// 		}
// 	}
// 	mut actor := Actor{}
// 	actor.methods = methods
// 	actor.structure = generate_actor_struct(actor.name)

// 	return actor
// }

// pub fn parse_config(path string) !ActorConfig {
// 	mut config_file := pathlib.get_file(path: path)!
// 	actor := json.decode(ActorConfig, config_file.read()!)!
// 	return actor
// }

// pub fn parse_readme(path string) !Actor {
// 	readme := markdownparser.new(path: '${path}/README.md')!
// 	name_header := readme.children()[1] as Header
// 	name := name_header.content
// 	return Actor{
// 		name: name
// 	}
// }



// pub fn (a Actor) generate_module() !Module {
// 	actor_struct := generate_actor_struct(a.name)


// 	mut files := [
// 		generate_factory_file(a.name),
// 	]
// 	// files << a.generate_model_files()!

// 	// generate code files for each of the objects the actor is responsible for
// 	for object in a.objects {
// 		files << generate_object_code(actor_struct, object)
// 		files << generate_object_test_code(actor_struct, object)!
// 	}

// 	// generate code files for each of the objects the actor is responsible for
// 	mut methods_file := VFile {}
// 	mut items :=


// 	return Module{
// 		name: a.name
// 		files: files
// 		misc_files: [readme]
// 	}
// }


// pub fn generate_object_code(actor Struct, object BaseObject) VFile {
// 	obj_name := texttools.name_fix_pascal_to_snake(object.structure.name)
// 	object_type := object.structure.name

// 	mut items := []CodeItem{}
// 	items = [generate_new_method(actor, object), generate_get_method(actor, object),
// 		generate_set_method(actor, object), generate_delete_method(actor, object),
// 		generate_list_result_struct(actor, object), generate_list_method(actor, object)]

// 	items << generate_object_methods(actor, object)
// 	mut file := codemodel.new_file(
// 		mod: texttools.name_fix(actor.name)
// 		name: obj_name
// 		imports: [
// 			Import{
// 				mod: object.structure.mod
// 				types: [object_type]
// 			},
// 			Import{
// 				mod: 'freeflowuniverse.crystallib.baobab.backend'
// 				types: ['FilterParams']
// 			},
// 		]
// 		items: items
// 	)

// 	if object.structure.fields.any(it.attrs.any(it.name == 'index')) {
// 		// can't filter without indices
// 		filter_params := generate_filter_params(actor, object)
// 		file.items << filter_params.map(CodeItem(it))
// 		file.items << generate_filter_method(actor, object)
// 	}

// 	return file
// }


// pub fn (a Actor) generate_model_files() ![]VFile {
// 	structs := a.objects.map(it.structure)
// 	return a.objects.map(codemodel.new_file(
// 		mod: texttools.name_fix(a.name)
// 		name: '${texttools.name_fix(it.structure.name)}_model'
// 		// imports: [Import{mod:'freeflowuniverse.crystallib.baobab.actor'}]
// 		items: [it.structure]
// 	))
// }

// pub fn generate_actor_module(name string, objects []BaseObject) !Module {
// 	actor := generate_actor_struct(name)
// 	mut files := [generate_factory_file(name)]

// 	// generate code files for each of the objects the actor is responsible for
// 	for object in objects {
// 		files << generate_object_code(actor, object)
// 		files << generate_object_test_code(actor, object)!
// 	}
// 	return Module{
// 		name: name
// 		files: files
// 	}
// }

// pub struct GenerateActorParams {
// 	model_path string
// }

// pub fn generate_factory_file(name string) VFile {
// 	actor_struct := generate_actor_struct(name)
// 	actor_factory := generate_actor_factory(actor_struct)
// 	return codemodel.new_file(
// 		mod: texttools.name_fix(name)
// 		name: 'actor'
// 		imports: [Import{
// 			mod: 'freeflowuniverse.crystallib.baobab.actor'
// 		}]
// 		items: [actor_struct, actor_factory]
// 	)
// }

// pub fn generate_actor_struct(name string) Struct {
// 	return Struct{
// 		is_pub: true
// 		name: '${name.title()}'
// 		embeds: [Struct{
// 			name: 'actor.Actor'
// 		}]
// 	}
// }

// // generate_actor_factory generates the factory function for an actor
// pub fn generate_actor_factory(actor Struct) Function {
// 	mut function := codemodel.parse_function('pub fn get(config actor.ActorConfig) !${actor.name}') or {
// 		panic(err)
// 	}
// 	function.body = 'return ${actor.name}{Actor: actor.new(config)!}'
// 	return function
// }




// fn get_children(s Struct, code []CodeItem) []Struct {
// 	structs := code.filter(it is Struct).map(it as Struct)
// 	mut children := []Struct{}
// 	for structure in structs {
// 		if s.fields.any(it.typ.symbol == structure.name) {
// 			children << structure
// 			children << get_children(structure, code)
// 		}
// 	}

// 	return children
// }