module main

import freeflowuniverse.crystallib.core.codemodel
import freeflowuniverse.crystallib.core.codeparser
import freeflowuniverse.crystallib.core.texttools
import os

// path to the circles module
const circles_path = os.dir(os.dir(@FILE))

pub struct GenerateDefinersParams {
	model_path   string
	circle_model string
}

// generate_methods generates methods to define the root aand sub objects in a model
pub fn generate_definers(params GenerateDefinersParams) ! {
	circle_code := codeparser.parse_v(params.circle_model)!
	circle_model_structs := circle_code.filter(it is codemodel.Struct).map(it as codemodel.Struct)
	circle_structs := circle_model_structs.filter(it.name == 'Circle')
	if circle_structs.len != 1 {
		return error('Circle struct not found')
	}
	circle_struct := circle_structs[0]

	code := codeparser.parse_v(params.model_path)!
	structs := code.filter(it is codemodel.Struct).map(it as codemodel.Struct)
	root_objects := structs.filter(it.attrs.any(it.name == 'root_object'))

	mut definers := []codemodel.Function{}

	for structure in root_objects {
		if !structure.is_pub {
			// todo: document reason
			continue
		}
		// get structs that are sub objects of the root object
		sub_objects := structs.filter(structure.fields
			.map(it.typ.symbol)
			.contains(it.name))

		definers << generate_root_object_definers(
			circle_struct: circle_struct
			root_struct:   structure
			sub_structs:   sub_objects
		)!
	}

	model_name := params.model_path.all_after_last('/').trim_string_right('_model.v')
	definers_path := '${circles_path}/${model_name}_definers.v'
	definers_code := definers.map(it.vgen()).join('\n')
	code_str := $tmpl('./templates/definers.v.template')
	os.write_file(definers_path, code_str)!
	os.execute('v fmt -w ${definers_path}')
}

struct GenerateRootObjectDefiner {
	structure     codemodel.Struct
	circle_struct codemodel.Struct
	root_struct   codemodel.Struct
	sub_structs   []codemodel.Struct
}

pub fn generate_root_object_definers(params GenerateRootObjectDefiner) ![]codemodel.Function {
	$if debug {
		println('Generating definers for root object: ${params.root_struct.name}')
	}

	root_struct_name := params.root_struct.name

	// field in circle where map of root object addresses are stored
	circle_fields := params.circle_struct.fields.filter(it.typ.symbol == root_struct_name)
	if circle_fields.len == 0 {
		return error('Field of type map[string]&${params.root_struct.name} not found in circle')
	}
	circle_field := circle_fields[0]

	method_body := '
		id := rand.uuid_v4()
		circle.${circle_field.name}[id] = params
	'

	root_obj_definer := codemodel.Function{
		receiver: codemodel.Param{
			name:    'circle'
			struct_: params.circle_struct
			mutable: true
		}
		name:     'define_${texttools.name_fix(params.root_struct.name)}'
		params:   [
			codemodel.Param{
				name:    'params'
				struct_: params.root_struct
			},
		]
		result:   codemodel.Result{
			result: true
		}
		body:     method_body
	}

	mut sub_object_definers := []codemodel.Function{}
	for structure in params.sub_structs {
		sub_object_definers << generate_sub_object_definer(
			root_struct:   params.root_struct
			circle_struct: params.circle_struct
			structure:     structure
		)!
	}
	mut definers := [root_obj_definer]
	definers << sub_object_definers
	return definers
}

pub struct GenerateSubObjectDefiner {
	structure     codemodel.Struct
	circle_struct codemodel.Struct
	root_struct   codemodel.Struct
}

pub fn generate_sub_object_definer(params GenerateSubObjectDefiner) !codemodel.Function {
	$if debug {
		println('Generating definers for sub object: ${params.structure.name}')
	}

	root_struct_name := params.root_struct.name

	// field in circle where map of root object addresses are stored
	circle_fields := params.circle_struct.fields.filter(it.typ.symbol == root_struct_name)
	if circle_fields.len == 0 {
		return error('Field of type map[string]&${params.root_struct.name} not found in circle')
	}
	circle_field := circle_fields[0]

	// field of sub object struct which holds the id of the root object
	root_id_fields := params.structure.fields.filter(it.attrs.any(it.name == 'root_object'))
	if root_id_fields.len == 0 {
		return error('Failed to find field in sub object that holds the id of the root object')
	}
	root_id_field := root_id_fields[0]

	// field in root object where sub object is stored
	// todo: make more reliable and support more modes of keeping subobjects
	root_object_fields := params.root_struct.fields.filter(it.typ.symbol.contains('${params.structure.name}'))
	if root_id_fields.len == 0 {
		return error('Failed to find field ')
	}

	root_object_field := root_object_fields[0]
	method_body := '
		root_obj := circle.${circle_field.name}[params.${root_id_field.name}]
		root_obj.${root_object_field.name} << params
	'

	sub_obj_definer := codemodel.Function{
		receiver: codemodel.Param{
			name:    'circle'
			struct_: params.circle_struct
			mutable: true
		}
		name:     'define_${texttools.name_fix(params.structure.name)}'
		params:   [
			codemodel.Param{
				name:    'params'
				struct_: params.structure
			},
		]
		result:   codemodel.Result{
			result: true
		}
		body:     method_body
	}
	return sub_obj_definer
}
