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

pub fn generate_actor_module(spec ActorSpecification) !Module {
	mut files := []IFile{}
	
	files = [
		generate_readme_file(spec)!,
		generate_actor_file(spec)!,
		generate_actor_test_file(spec)!,
		generate_handle_file(spec)!,
		generate_methods_file(spec)!
		generate_client_file(spec)!
	]

	mut docs_files := []IFile{}

	// generate code files for supported interfaces
	for iface in spec.interfaces {
		match iface {
			.openrpc {
				// convert actor spec to openrpc spec
				openrpc_spec := spec.to_openrpc()
				
				// generate openrpc code files
				files << generate_openrpc_client_file(openrpc_spec)!
				files << generate_openrpc_client_test_file(openrpc_spec)!

				// add openrpc.json to docs
				docs_files << generate_openrpc_file(openrpc_spec)!
			} 
			.command {
				files << generate_command_file(spec)!
			}
			else {
				return error('unsupported interface ${iface}')
			}
		}
	}

	// folder with docs
	docs_folder := Folder {
		name: 'docs'
		files: docs_files
	}
	
	// create module with code files and docs folder
	name_fixed := texttools.name_fix_snake(spec.name)
	return codemodel.new_module(
		name: '${name_fixed}_actor'
		files: files
		folders: [docs_folder]
	)
}

fn generate_readme_file(spec ActorSpecification) !File {
	return File{
		name: 'README'
		extension: 'md'
		content: '# ${spec.name}\n${spec.description}'
	}
}

fn generate_actor_file(spec ActorSpecification) !VFile {
	dollar := '$'
	actor_name_snake := texttools.name_fix_snake(spec.name)
	actor_name_pascal := texttools.name_fix_snake_to_pascal(spec.name)
	code := $tmpl('./templates/actor.v.template')
	return VFile {
		name: 'actor'
		items: [CustomCode{code}]
	}
}

fn generate_actor_test_file(spec ActorSpecification) !VFile {
	dollar := '$'
	actor_name_snake := texttools.name_fix_snake(spec.name)
	actor_name_pascal := texttools.name_fix_snake_to_pascal(spec.name)
	code := $tmpl('./templates/actor_test.v.template')
	return VFile {
		name: 'actor_test'
		items: [CustomCode{code}]
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