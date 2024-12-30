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

pub fn generate_methods_file(spec ActorSpecification) !VFile {
	actor_name_snake := texttools.name_fix_snake(spec.name)
	actor_name_pascal := texttools.name_fix_snake_to_pascal(spec.name)
	
	mut items := []CodeItem{}
	for method in spec.methods {
		items << CustomCode{generate_method_function(spec.name, method)!}
	}
	
	return VFile {
		name: 'methods'
		items: items
	}
}

pub fn generate_method_function(actor_name string, method ActorMethod) !string {
	actor_name_pascal := texttools.name_fix_snake_to_pascal(actor_name)
	name_fixed := texttools.name_fix_snake(method.name)
	mut handler := '// Method for ${name_fixed}\n'
	params := if method.func.params.len > 0 {
		method.func.params.map(it.vgen()).join(', ')
	} else {''}
	handler += "fn (mut actor ${actor_name_pascal}Actor) ${name_fixed}(${params}) ! {}"
	return handler
}