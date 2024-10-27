module generator

import freeflowuniverse.crystallib.core.codemodel { CodeFile, CodeItem, Function, Import, Param, Result, Struct, StructField, Type }
import freeflowuniverse.crystallib.core.codeparser
import freeflowuniverse.crystallib.core.texttools
import os

const id_param = Param{
	name: 'id'
	typ: Type{
		symbol: 'u32'
	}
}

pub fn generate_object_code(actor Struct, object BaseObject) CodeFile {
	obj_name := texttools.name_fix_pascal_to_snake(object.structure.name)
	object_type := object.structure.name

	mut items := []CodeItem{}
	items = [generate_new_method(actor, object), generate_get_method(actor, object),
		generate_set_method(actor, object), generate_delete_method(actor, object),
		generate_list_result_struct(actor, object), generate_list_method(actor, object)]

	items << generate_object_methods(actor, object)
	mut file := codemodel.new_file(
		mod: texttools.name_fix(actor.name)
		name: obj_name
		imports: [
			Import{
				mod: object.structure.mod
				types: [object_type]
			},
			Import{
				mod: 'freeflowuniverse.crystallib.baobab.backend'
				types: ['FilterParams']
			},
		]
		items: items
	)

	if object.structure.fields.any(it.attrs.any(it.name == 'index')) {
		// can't filter without indices
		filter_params := generate_filter_params(actor, object)
		file.items << filter_params.map(CodeItem(it))
		file.items << generate_filter_method(actor, object)
	}

	return file
}

// generate_object_methods generates CRUD actor methods for a provided structure
fn generate_get_method(actor Struct, object BaseObject) Function {
	object_name := texttools.name_fix_pascal_to_snake(object.structure.name)
	object_type := object.structure.name

	get_method := Function{
		name: 'get_${object_name}'
		description: 'gets the ${object_name} with the given object id'
		receiver: Param{
			mutable: true
			name: 'actor'
			typ: Type{
				symbol: actor.name
			}
		}
		params: [generator.id_param]
		result: Result{
			typ: Type{
				symbol: object.structure.name
			}
			result: true
		}
		body: 'return actor.backend.get[${object_type}](id)!'
	}
	return get_method
}

// generate_object_methods generates CRUD actor methods for a provided structure
fn generate_set_method(actor Struct, object BaseObject) Function {
	object_name := texttools.name_fix_pascal_to_snake(object.structure.name)
	object_type := object.structure.name

	param_getters := generate_param_getters(
		structure: object.structure
		prefix: ''
		only_mutable: true
	)
	body := 'actor.backend.set[${object_type}](${object_name})!'
	get_method := Function{
		name: 'set_${object_name}'
		description: 'updates the ${object.structure.name} with the given object id'
		receiver: Param{
			mutable: true
			name: 'actor'
			typ: Type{
				symbol: actor.name
			}
		}
		params: [
			Param{
				name: object_name
				typ: Type{
					symbol: object_type
				}
			},
		]
		result: Result{
			result: true
		}
		body: body
	}
	return get_method
}

// generate_object_methods generates CRUD actor methods for a provided structure
fn generate_delete_method(actor Struct, object BaseObject) Function {
	object_name := texttools.name_fix_pascal_to_snake(object.structure.name)
	object_type := object.structure.name

	body := 'actor.backend.delete[${object_type}](id)!'
	get_method := Function{
		name: 'delete_${object_name}'
		description: 'deletes the ${object.structure.name} with the given object id'
		receiver: Param{
			mutable: true
			name: 'actor'
			typ: Type{
				symbol: actor.name
			}
		}
		params: [generator.id_param]
		result: Result{
			result: true
		}
		body: body
	}
	return get_method
}

// generate_object_methods generates CRUD actor methods for a provided structure
fn generate_new_method(actor Struct, object BaseObject) Function {
	object_name := texttools.name_fix_pascal_to_snake(object.structure.name)
	object_type := object.structure.name

	param_getters := generate_param_getters(
		structure: object.structure
		prefix: ''
		only_mutable: false
	)
	body := 'return actor.backend.new[${object_type}](${object_name})!'
	new_method := Function{
		name: 'new_${object_name}'
		description: 'news the ${object.structure.name} with the given object id'
		receiver: Param{
			name: 'actor'
			typ: Type{
				symbol: actor.name
			}
			mutable: true
		}
		params: [
			Param{
				name: object_name
				typ: Type{
					symbol: object_type
				}
			},
		]
		result: Result{
			result: true
			typ: Type{
				symbol: 'u32'
			}
		}
		body: body
	}
	return new_method
}

// generate_object_methods generates CRUD actor methods for a provided structure
fn generate_list_result_struct(actor Struct, object BaseObject) Struct {
	object_name := texttools.name_fix_pascal_to_snake(object.structure.name)
	object_type := object.structure.name
	return Struct{
		name: '${object_type}List'
		is_pub: true
		fields: [
			StructField{
				name: 'items'
				typ: Type{
					symbol: '[]${object_type}'
				}
			},
		]
	}
}

// generate_object_methods generates CRUD actor methods for a provided structure
fn generate_list_method(actor Struct, object BaseObject) Function {
	object_name := texttools.name_fix_pascal_to_snake(object.structure.name)
	object_type := object.structure.name

	list_struct := Struct{
		name: '${object_type}List'
		fields: [
			StructField{
				name: 'items'
				typ: Type{
					symbol: '[]${object_type}'
				}
			},
		]
	}

	param_getters := generate_param_getters(
		structure: object.structure
		prefix: ''
		only_mutable: false
	)
	body := 'return ${object_type}List{items:actor.backend.list[${object_type}]()!}'
	mut result := Result{
		structure: generate_list_result_struct(actor, object)
	}
	result.typ.symbol = result.structure.name
	result.result = true
	new_method := Function{
		name: 'list_${object_name}'
		description: 'lists all of the ${object_name} objects'
		receiver: Param{
			name: 'actor'
			typ: Type{
				symbol: actor.name
			}
			mutable: true
		}
		params: []
		result: result
		body: body
	}
	return new_method
}

fn generate_filter_params(actor Struct, object BaseObject) []Struct {
	object_name := texttools.name_fix_pascal_to_snake(object.structure.name)
	object_type := object.structure.name

	return [
		Struct{
			name: 'Filter${object_type}Params'
			fields: [
				StructField{
					name: 'filter'
					typ: Type{
						symbol: '${object_type}Filter'
					}
				},
				StructField{
					name: 'params'
					typ: Type{
						symbol: 'FilterParams'
					}
				},
			]
		},
		Struct{
			name: '${object_type}Filter'
			fields: object.structure.fields.filter(it.attrs.any(it.name == 'index'))
		},
	]
}

// generate_object_methods generates CRUD actor methods for a provided structure
fn generate_filter_method(actor Struct, object BaseObject) Function {
	object_name := texttools.name_fix_pascal_to_snake(object.structure.name)
	object_type := object.structure.name

	param_getters := generate_param_getters(
		structure: object.structure
		prefix: ''
		only_mutable: false
	)
	params_type := 'Filter${object_type}Params'
	body := 'return actor.backend.filter[${object_type}, ${object_type}Filter](filter.filter, filter.params)!'
	return Function{
		name: 'filter_${object_name}'
		description: 'lists all of the ${object_name} objects'
		receiver: Param{
			name: 'actor'
			typ: Type{
				symbol: actor.name
			}
			mutable: true
		}
		params: [
			Param{
				name: 'filter'
				typ: Type{
					symbol: params_type
				}
			},
		]
		result: Result{
			typ: Type{
				symbol: '[]${object_type}'
			}
			result: true
		}
		body: body
	}
}

// generate_object_methods generates CRUD actor methods for a provided structure
fn generate_object_methods(actor Struct, object BaseObject) []Function {
	object_name := texttools.name_fix_pascal_to_snake(object.structure.name)
	object_type := object.structure.name

	mut funcs := []Function{}
	for method in object.methods {
		mut params := [Param{
			name: 'id'
			typ: Type{
				symbol: 'u32'
			}
		}]
		params << method.params
		funcs << Function{
			name: method.name
			description: method.description
			receiver: Param{
				name: 'actor'
				typ: Type{
					symbol: actor.name
				}
				mutable: true
			}
			params: params
			result: method.result
			body: 'obj := actor.backend.get[${method.receiver.typ.symbol}](id)!
			obj.${method.name}(${method.params.map(it.name).join(',')})
			actor.backend.set[${method.receiver.typ.symbol}](obj)!
			'
		}
	}

	return funcs
}

@[params]
struct GenerateParamGetters {
	structure    Struct
	prefix       string
	only_mutable bool // if true generates param.get methods for only mutable  struct fields. Used for updating.
}

fn generate_param_getters(params GenerateParamGetters) []string {
	mut param_getters := []string{}
	fields := if params.only_mutable {
		params.structure.fields.filter(it.is_mut && it.is_pub)
	} else {
		params.structure.fields.filter(it.is_pub)
	}
	for field in fields {
		if field.typ.symbol.starts_with_capital() {
			subgetters := generate_param_getters(GenerateParamGetters{
				...params
				structure: field.structure
				prefix: '${field.name}_'
			})
			// name of the tested object, used for param declaration
			// ex: fruits []Fruit becomes fruit_name
			nested_name := field.structure.name.to_lower()
			if field.typ.is_map {
				param_getters.insert(0, '${nested_name}_key := params.get(\'${nested_name}_key\')!')
				param_getters << '${field.name}: {${nested_name}_key: ${field.structure.name}}{'
			} else if field.typ.is_array {
				param_getters << '${field.name}: [${field.structure.name}{'
			} else {
				param_getters << '${field.name}: ${field.structure.name}{'
			}
			param_getters << subgetters
			param_getters << if field.typ.is_array { '}]' } else { '}' }
			continue
		}

		mut get_method := '${field.name}: params.get'
		if field.typ.symbol != 'string' {
			// TODO: check if params method actually exists
			'get_${field.typ.symbol}'
		}

		if field.default != '' {
			get_method += '_default'
		}

		get_method = get_method + "('${params.prefix}${field.name}')!"
		param_getters << get_method
	}
	return param_getters
}

@[params]
struct GetChildField {
	parent Struct @[required]
	child  Struct @[required]
}

fn get_child_field(params GetChildField) StructField {
	fields := params.parent.fields.filter(it.typ.symbol == 'map[string]&${params.child.name}')
	if fields.len != 1 {
		panic('this should never happen')
	}
	return fields[0]
}
