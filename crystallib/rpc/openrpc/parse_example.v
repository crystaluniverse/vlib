module openrpc

import freeflowuniverse.crystallib.data.jsonschema { Reference }
import freeflowuniverse.crystallib.core.codemodel { Struct, StructField }
import json
import x.json2

pub fn parse_example_pairing(text_ string) !ExamplePairing {
	if !text_.contains('Example:') {
		return error('no example found fitting format')
	}
	mut text := text_.all_after('Example:').trim_space()

	mut pairing := ExamplePairing{}

	if text.contains('assert') {
		pairing.name = if text.all_before('assert').trim_space() != '' {
			text.all_before('assert').trim_space()
		} else {
			text.all_after('assert').all_before('(').trim_space()
		}
		value := text.all_after('==').all_before('//').trim_space()
		pairing.params = parse_pairing_params(text.all_after('(').all_before(')'))
		pairing.result = parse_pairing_result(text)
		description := text.all_after('//').trim_space()
	}

	return pairing
}

pub fn parse_struct_example(structure Struct) Example {
	mut val_map := map[string]json2.Any{}
	for field in structure.fields {
		example_attr := field.attrs.filter(it.name == 'example')
		example_val := if example_attr.len == 1 {
			example_attr[0].arg
		} else {
			generate_example_val(field)
		}
		val_map[field.name] = example_val
	}
	return Example{
		name:  '${structure.name}Example'
		value: json2.encode(val_map)
	}
}

pub fn generate_example_val(field StructField) string {
	return ''
}

pub fn parse_pairing_params(text_ string) []ExampleRef {
	mut text := text_.trim_space()
	mut examples := []ExampleRef{}

	if text.is_lower() && !text.contains("'") && !text.contains('"') {
		examples << Reference{text}
	} else if text.contains(':') {
		examples << Example{
			name:  ''
			value: json.encode(text)
		}
	} else {
		examples1 := text.split(',').map(it.trim_space()).map(ExampleRef(Example{
			name:  ''
			value: it
		}))

		examples << examples1
	}
	return examples
}

pub fn parse_pairing_result(text_ string) ExampleRef {
	mut text := text_.trim_space()

	if text.is_lower() {
		return Reference{text}
	} else if text.contains(':') {
		return Example{
			name:  ''
			value: json.encode(text)
		}
	}
	return Example{}
}

// pub fn parse_example(text string) openrpc.Example {
// 	return Example{

// 	}
// }
