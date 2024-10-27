module generator

import freeflowuniverse.crystallib.core.codemodel
import freeflowuniverse.crystallib.core.codeparser
import os
import freeflowuniverse.crystallib.ui.console

// // generate_object_methods generates CRUD actor methods for a provided structure
// pub fn (generator ActorGenerator) generate_object_methods(structure codemodel.Struct) []codemodel.Function {
// 	return [
// 		generator.generate_get_method(structure),
// 		// generator.generate_set_method(structure),
// 		// generator.generate_delete_method(structure),
// 		// generator.generate_get_method(structure),
// 	]
// }

// generate_object_methods generates CRUD actor methods for a provided structure
pub fn test_generate_get_method() {
	generator := ActorGenerator{'test'}
	actor_struct := codemodel.Struct{
		name: 'TestActor'
		fields: [
			codemodel.StructField{
				name: 'test_struct_map'
				typ: codemodel.Type{
					symbol: 'map[string]&TestStruct'
				}
			},
		]
	}

	test_struct := codemodel.Struct{
		name: 'TestStruct'
	}
	field := get_child_field(
		parent: actor_struct
		child: test_struct
	)

	method := generator.generate_get_method(
		actor_name: actor_struct.name
		actor_field: field
		root_struct: test_struct
	)
	// console.print_debug(method.vgen())
}

// // generate_object_methods generates CRUD actor methods for a provided structure
// pub fn (generator ActorGenerator) generate_set_method(structure codemodel.Struct) codemodel.Function {
// 	params_getter := "id := params.get('id')!"
// 	field := generator.get_object_field(structure)
// 	object_getter := 'object := actor.${field.name}[id]'
// 	body := '${params_getter}\n${object_getter}\nreturn object'
// 	get_method := codemodel.Function{
// 		name: 'get_${generator.model_name}'
// 		description: 'gets the ${structure.name} with the given object id'
// 		receiver: codemodel.Param{
// 			name: 'actor'
// 			struct_: generator.actor_struct
// 		}
// 		params: [
// 			codemodel.Param{
// 				name: 'id'
// 				typ: codemodel.Type{
// 					symbol: 'string'
// 				}
// 			},
// 		]
// 		result: codemodel.Result{
// 			structure: structure
// 		}
// 		body: body
// 	}
// 	return get_method
// }

// // generate_object_methods generates CRUD actor methods for a provided structure
// pub fn (generator ActorGenerator) generate_get_method(structure codemodel.Struct) codemodel.Function {
// 	params_getter := "id := params.get('id')!"
// 	field := generator.get_object_field(structure)
// 	object_getter := 'object := actor.${field.name}[id]'
// 	body := '${params_getter}\n${object_getter}\nreturn object'
// 	get_method := codemodel.Function{
// 		name: 'get_${generator.model_name}'
// 		description: 'gets the ${structure.name} with the given object id'
// 		receiver: codemodel.Param{
// 			name: 'actor'
// 			struct_: generator.actor_struct
// 		}
// 		params: [
// 			codemodel.Param{
// 				name: 'id'
// 				typ: codemodel.Type{
// 					symbol: 'string'
// 				}
// 			},
// 		]
// 		result: codemodel.Result{
// 			structure: structure
// 		}
// 		body: body
// 	}
// 	return get_method
// }

// // generate_object_methods generates CRUD actor methods for a provided structure
// pub fn (generator ActorGenerator) generate_delete_method(structure codemodel.Struct) codemodel.Function {
// 	params_getter := "id := params.get('id')!"
// 	field := generator.get_object_field(structure)
// 	object_getter := 'object := actor.${field.name}[id]'
// 	body := '${params_getter}\n${object_getter}\nreturn object'
// 	get_method := codemodel.Function{
// 		name: 'get_${generator.model_name}'
// 		description: 'gets the ${structure.name} with the given object id'
// 		receiver: codemodel.Param{
// 			name: 'actor'
// 			struct_: generator.actor_struct
// 		}
// 		params: [
// 			codemodel.Param{
// 				name: 'id'
// 				typ: codemodel.Type{
// 					symbol: 'string'
// 				}
// 			},
// 		]
// 		result: codemodel.Result{
// 			structure: structure
// 		}
// 		body: body
// 	}
// 	return get_method
// }

// pub fn (generator ActorGenerator) get_object_field(structure codemodel.Struct) codemodel.StructField {
// 	fields := generator.actor_struct.fields.filter(it.typ.symbol == 'map[string]&${structure.name}')
// 	if fields.len != 1 {
// 		panic('this should never happen')
// 	}
// 	return fields[0]
// }
