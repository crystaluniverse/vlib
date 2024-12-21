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
	for i in spec.methods {
		items << CustomCode{generate_method_function(i)!}
	}
	
	return VFile {
		name: 'methods'
		items: items
	}
}

pub fn generate_method_function(method ActorMethod) !string {
	name_fixed := texttools.name_fix_snake(method.name)
	mut handler := '// Method for ${name_fixed}\n'
	params := if method.func.params.len > 0 {
		method.func.params.map(it.vgen()).join(', ')
	} else {''}
	handler += "fn (mut actor Actor) ${name_fixed}(${params}) ! {}"
	return handler
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
