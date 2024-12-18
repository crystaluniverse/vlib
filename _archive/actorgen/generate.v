module generator

import freeflowuniverse.crystallib.core.codemodel
import freeflowuniverse.crystallib.core.pathlib

@[params]
pub struct GenerateParams {
	source_model pathlib.Path @[required] // path of model(s) for which actor(s) will be generated
	destination  pathlib.Path // path where actor code will be outputted to
}

// generate generates actor code from model code
pub fn (generator ActorGenerator) generate(code []codemodel.CodeItem) ![]codemodel.CodeItem {
	root_structs := generator.get_root_structs(code)
	actor_struct := generator.generate_actor_struct()

	mut crud_methods := []codemodel.Function{}
	for root_struct in root_structs {
		field := get_child_field(
			parent: actor_struct
			child:  root_struct
		)
		crud_methods << generator.generate_object_methods(
			actor_field: field
			actor_name:  actor_struct.name
			root_struct: root_struct
		)
	}

	handler_method := generator.generate_handler_method(crud_methods)
	// actor_code := $tmpl('templates/actor.v.template')

	custom_code := codemodel.CustomCode{
		// text: $tmpl('./templates/play.v.template')
	}

	mut actor_code := []codemodel.CodeItem{}
	actor_code << custom_code
	actor_code << actor_struct
	actor_code << handler_method
	for method in crud_methods {
		actor_code << method
	}
	return actor_code
}

// get_root_struct returns the root structs in code
pub fn (generator ActorGenerator) get_root_structs(code []codemodel.CodeItem) []codemodel.Struct {
	structs := code.filter(it is codemodel.Struct).map(it as codemodel.Struct)
	return structs.filter(it.attrs.any(it.name == 'root_object'))
}
