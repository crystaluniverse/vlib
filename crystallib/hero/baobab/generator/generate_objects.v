module generator

// pub fn generate_object_code(actor Struct, object BaseObject) VFile {
// 	obj_name := texttools.name_fix_snake(object.structure.name)
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
