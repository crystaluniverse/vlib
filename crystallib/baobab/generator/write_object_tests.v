module generator

import freeflowuniverse.crystallib.core.codemodel { CodeFile, CustomCode, Function, Import, Struct }
import freeflowuniverse.crystallib.core.codeparser
import rand
import freeflowuniverse.crystallib.core.texttools
import os

// generate_object_methods generates CRUD actor methods for a provided structure
pub fn generate_object_test_code(actor Struct, object BaseObject) !CodeFile {
	consts := CustomCode{"const db_dir = '\${os.home_dir()}/hero/db'
	const actor_name = '${actor.name}_test_actor'"}

	clean_code := 'mut actor := get(name: actor_name)!\nactor.backend.reset()!'

	testsuite_begin := Function{
		name: 'testsuite_begin'
		body: clean_code
	}

	testsuite_end := Function{
		name: 'testsuite_end'
		body: clean_code
	}

	actor_name := texttools.name_fix(actor.name)
	object_name := texttools.name_fix_pascal_to_snake(object.structure.name)
	object_type := object.structure.name
	// TODO: support modules outside of crystal

	mut file := CodeFile{
		name: '${object_name}_test'
		mod: texttools.name_fix(actor_name)
		imports: [
			Import{
				mod: 'os'
			},
			Import{
				mod: '${object.structure.mod}'
				types: [object_type]
			},
		]
		items: [
			consts,
			testsuite_begin,
			testsuite_end,
			generate_new_method_test(actor, object)!,
			generate_get_method_test(actor, object)!,
		]
	}

	if object.structure.fields.any(it.attrs.any(it.name == 'index')) {
		// can't filter without indices
		file.items << generate_filter_test(actor, object)!
	}

	return file
}

// generate_object_methods generates CRUD actor methods for a provided structure
fn generate_new_method_test(actor Struct, object BaseObject) !Function {
	object_name := texttools.name_fix_pascal_to_snake(object.structure.name)
	object_type := object.structure.name

	required_fields := object.structure.fields.filter(it.attrs.any(it.name == 'required'))
	mut fields := []string{}
	for field in required_fields {
		mut field_decl := '${field.name}: ${get_mock_value(field.typ.symbol)!}'
		fields << field_decl
	}

	body := 'mut actor := get(name: actor_name)!
	mut ${object_name}_id := actor.new_${object_name}(${object_type}{${fields.join(',')}})!
	assert ${object_name}_id == 1

	${object_name}_id = actor.new_${object_name}(${object_type}{${fields.join(',')}})!
	assert ${object_name}_id == 2'
	return Function{
		name: 'test_new_${object_name}'
		description: 'news the ${object_type} with the given object id'
		result: codemodel.Result{
			result: true
		}
		body: body
	}
}

// generate_object_methods generates CRUD actor methods for a provided structure
fn generate_get_method_test(actor Struct, object BaseObject) !Function {
	object_name := texttools.name_fix_pascal_to_snake(object.structure.name)
	object_type := object.structure.name

	required_fields := object.structure.fields.filter(it.attrs.any(it.name == 'required'))
	mut fields := []string{}
	for field in required_fields {
		mut field_decl := '${field.name}: ${get_mock_value(field.typ.symbol)!}'
		fields << field_decl
	}

	body := 'mut actor := get(name: actor_name)!
	mut ${object_name} := ${object_type}{${fields.join(',')}}
	${object_name}.id = actor.new_${object_name}(${object_name})!
	assert ${object_name} == actor.get_${object_name}(${object_name}.id)!'
	return Function{
		name: 'test_get_${object_name}'
		description: 'news the ${object_type} with the given object id'
		result: codemodel.Result{
			result: true
		}
		body: body
	}
}

// generate_object_methods generates CRUD actor methods for a provided structure
fn generate_filter_test(actor Struct, object BaseObject) !Function {
	object_name := texttools.name_fix_pascal_to_snake(object.structure.name)
	object_type := object.structure.name

	index_fields := object.structure.fields.filter(it.attrs.any(it.name == 'index'))
	if index_fields.len == 0 {
		return error('Cannot generate filter method test for object without any index fields')
	}

	mut index_tests := []string{}
	for i, field in index_fields {
		val := get_mock_value(field.typ.symbol)!
		index_field := '${field.name}: ${val}' // index field assignment line
		mut fields := [index_field]
		fields << get_required_fields(object.structure)!
		index_tests << '${object_name}_id${i} := actor.new_${object_name}(${object_type}{${fields.join(',')}})!
		${object_name}_list${i} := actor.filter_${object_name}(
			filter: ${object_type}Filter{${index_field}}
		)!
		assert ${object_name}_list${i}.len == 1
		assert ${object_name}_list${i}[0].${field.name} == ${val}
		'
	}

	body := 'mut actor := get(name: actor_name)!
	\n${index_tests.join('\n\n')}'

	return Function{
		name: 'test_filter_${object_name}'
		description: 'news the ${object_type} with the given object id'
		result: codemodel.Result{
			result: true
		}
		body: body
	}
}

fn get_required_fields(s Struct) ![]string {
	required_fields := s.fields.filter(it.attrs.any(it.name == 'required'))
	mut fields := []string{}
	for field in required_fields {
		fields << '${field.name}: ${get_mock_value(field.typ.symbol)!}'
	}
	return fields
}

fn get_mock_value(typ string) !string {
	if typ == 'string' {
		return "'mock_string_${rand.string(3)}'"
	} else if typ == 'int' || typ == 'u32' {
		return '42'
	} else {
		return error('mock values for types other than strings and numbers are not yet supported')
	}
}
