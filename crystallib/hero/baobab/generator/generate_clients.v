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

pub fn generate_client_file(spec ActorSpecification) !VFile {
	actor_name_snake := texttools.name_fix_snake(spec.name)
	actor_name_pascal := texttools.name_fix_snake_to_pascal(spec.name)
	
	mut items := []CodeItem{}

	items << CustomCode {'
	pub struct Client {
		actor.Client
	}

	fn new_client() Client {
		return Client{}
	}'}
	
	for method in spec.methods {
		items << CustomCode{generate_client_method(method)!}
	}
	
	return VFile {
		imports: [
			Import{
				mod: 'freeflowuniverse.crystallib.data.paramsparser'
			},
			Import{
				mod: 'freeflowuniverse.crystallib.hero.baobab.actor'
			}
		]
		name: 'client'
		items: items
	}
}

pub fn generate_client_method(method ActorMethod) !string {
	name_fixed := texttools.name_fix_snake(method.name)
	mut handler := '// Method for ${name_fixed}\n'
	params := if method.func.params.len > 0 {
		method.func.params.map(it.vgen()).join(', ')
	} else {''}

	call_params := if method.func.params.len > 0 {
		method.func.params.map(it.name).join(', ')
	} else {''}

	handler += "fn (mut client Client) ${name_fixed}(${params}) ! {
		client.call_to_action(
			method: ${name_fixed}
			params: paramsparser.encode(${call_params})
		)
	}"
	return handler
}