module scanner

import os
import regex
import json
import x.json2
// import hero_server.lib.openrpc.parser.example { load_example }
// import hero_server.lib.openrpc.parser.cleaner { cleaner, load }
// import hero_server.lib.openrpc.parser.splitter { splitter, CodeType }
// import hero_server.lib.openrpc.parser.includes { include_process_directory, includes_process_text }

pub struct Struct{
pub mut:
	name string
	comments []string
}


pub struct Enum{
pub mut:
	name string
	comments []string
}

pub struct Function{
pub mut:
	name string
	comments []string
}



// struct FieldDescription {
// 	description string
// 	index       bool
// 	example     ?json2.Any
// }

// fn parse_field_description(field_description string) FieldDescription {
// 	mut result := FieldDescription{
// 		description: '',
// 		index: false,
// 		example: none
// 	}

// 	mut desc := field_description.trim_space()
// 	if desc.ends_with('*') {
// 		result.index = true
// 		desc = desc[0..desc.len - 1].trim_space()
// 	}

// 	parts := desc.split('example=')
// 	result.description = parts[0].trim_space()

// 	if parts.len > 1 {
// 		example_value := parts[1].trim_space()
// 		if example_value.starts_with('[') && example_value.ends_with(']') {
// 			result.example = json.decode(Any, example_value) or { none }
// 		} else if example_value.int() or { -1 } > 0 {
// 			result.example = example_value.int()
// 		} else {
// 			// example_match := regex.find(r'["\'](.+?)["\']', example_value)
// 			// if example_match.matches {
// 			// 	result.example = example_match[0]
// 			// }
// 		}
// 	}

// 	return result
// }


struct Field {
	name        string
	field_type  string
	description string
}

// Parses the struct definition and returns the struct name and fields or an error
fn parse_struct(struct_def string) !(string, []Field) {
	// Initialize regex for struct name and fields
	mut struct_regex := regex.regex_opt(r'struct (\w+)')!
	mut field_regex := regex.regex_opt(r'\s+(\w+)\s+([\w\[\]]+)(?:\s*\/\/(.+))?')!

	// Find struct name
	mut struct_name_start, mut struct_name_end := struct_regex.find(struct_def)
	if struct_name_start < 0 {
		return error('Struct name not found')
	}
	
	struct_name_start += 'struct '.len
	
	struct_name := struct_def[struct_name_start..struct_name_end]

	// Find fields in the struct definition
	pairs := field_regex.find_all(struct_def) // [0,5, 6,7, 9,18]
	mut fields := []Field{}

	for i:=0; i < pairs.len; i+=2 {
		start := pairs[i]
		end := pairs[i + 1]
		parts := struct_def[start..end].split(' ')
		if parts.len < 2 {
			continue
		}

		field_name := parts[0]
		field_type := parts[1]
		field_description := if parts.len > 3 { parts[3..].join(' ').all_after('//').trim_space() } else { '' }
		fields << Field{
			name: field_name
			field_type: field_type
			description: field_description
		}
	}

	return struct_name, fields
}


// fn parse_struct(struct_def string) !(string, []Field) {
// 	mut struct_re := regex.regex_opt(r"struct (\w+)")!
// 	start, end := struct_re.find(struct_def)

// 	fields := re.find_all(r"\s+(\w+)\s+([\w\[\]]+)(?:\s*//(.+))?", struct_def)
// 	return struct_name, fields
// }

fn parse_enum(enum_def string) (string, []string) {
	enum_name := regex.find(r"enum (\w+)", enum_def)[0]
	values := regex.find_all(r"\n\s+(\w+)", enum_def)
	return enum_name, values
}

// fn parse_function(func_def string) (string, []Parameter, string) {
// 	match := regex.find(r"fn (\w+)\((.*?)\)\s*(!?\w*)", func_def)
// 	if match.matches {
// 		func_name := match[0]
// 		params_str := match[1].trim_space()
// 		mut return_type := match[2].trim_space()

// 		if return_type.starts_with("RO_") {
// 			return_type = return_type[3..]
// 		}

// 		mut params := []Parameter{}
// 		if params_str != '' {
// 			param_pattern := regex.compile(r"(\w+)(?:\s+(\w+))?")
// 			for param_match in param_pattern.find_all(params_str) {
// 				param_name := param_match[0]
// 				param_type := param_match[1]
// 				if param_type.starts_with("RO_") {
// 					param_type = param_type[3..]
// 				}
// 				params << Parameter{ name: param_name, type: param_type }
// 			}
// 		}

// 		return func_name, params, return_type
// 	}
// 	return '', []Parameter{}, ''
// }

// fn get_type_schema(type_name string) map[string]string {
// 	if type_name.starts_with('[]') {
// 		return { 'type': 'array', 'items': get_type_schema(type_name[2..]) }
// 	}
// 	match type_name {
// 		'string' { return { 'type': 'string' } }
// 		'f64', 'float', 'f32', 'f16' { return { 'type': 'number' } }
// 		'int' { return { 'type': 'integer' } }
// 		'bool' { return { 'type': 'boolean' } }
// 		'' { return { 'type': 'null' } }
// 		else { return { '\$ref': '#/components/schemas/$type_name' } }
// 	}
// }

fn parser(code_ string, path string)! map[string]json2.Any {
	mut code := code_
	if code.len > 0 && path.len > 0 {
		return error('cannot have code and path filled in at same time')
	}

	mut includes_dict := match path{
		'' {
			includes_process_text(path)
		}
		else{
			include_process_directory(path)!
		}
	}


	mut openrpc_spec := map[string]json2.Any{}
	openrpc_spec['openrpc'] = '1.2.6'
	mut info := map[string]json2.Any{}
	info['title'] = 'V Code API'
	info['version'] = '1.0.0'
	openrpc_spec['info'] = json2.Any(info)
	openrpc_spec['components'] = map[string]json2.Any{}
	mut components := map[string]json2.Any{}
	components['schemas'] = map[string]json2.Any{}
	openrpc_spec['components'] = json2.Any(components)


	code = cleaner(code)!
	code = include_process_text(code, includes_dict)
	codeblocks := splitter(code)

	mut structs := []Struct{}
	mut enums := []Enum{}
	mut functions := []Function{}

	for item in codeblocks {
		match item.code_type {
			.struct_ {
				structs << Struct{ name: item.block, comments: item.comments }
			}
			.enum_ {
				enums << Enum{ name: item.block, comments: item.comments }
			}
			.function {
				functions << Function{ name: item.block, comments: item.comments }
			}
		}
	}

	for struct_ in structs {
		struct_name, fields := parse_struct(struct_.name)
		mut cmps := openrpc_spec['components'].as_map()
		mut schemas := cmps['schemas'].as_map()
		mut struct_schema := map[string]json2.Any{}
		struct_schema['type'] = 'object'
		struct_schema['properties'] = map[string]json2.Any{}
		schemas[struct_name] = struct_schema
		cmps['schemas'] = schemas
		
		
		for field in fields {
			field_name, field_type, field_description := field
			parsed_description := parse_field_description(field_description)
			mut field_schema := get_type_schema(field_type)
			field_schema['description'] = parsed_description.description
			if parsed_description.example {
				field_schema['example'] = parsed_description.example
			}
			if parsed_description.index {
				field_schema['x-tags'] = field_schema['x-tags'] + ['indexed']
			}
			openrpc_spec['components']['schemas'][struct_name]['properties'][field_name] = field_schema
		}
	}

	for enum_ in enums {
		enum_name, values := parse_enum(enum_.name)
		openrpc_spec['components']['schemas'][enum_name] = map[string]json2.Any{}
		openrpc_spec['type'] = 'string'
		openrpc_spec['enum'] = values
	}

	for function in functions {
		func_name, params, return_type := parse_function(function.name)
		mut method := map[string]Any{
			'name': func_name,
			'description': 'Executes the $func_name function',
			'params': []Any{},
			'result': {
				'name': 'result',
				'description': 'Result of the $func_name function is $return_type',
				'schema': get_type_schema(return_type)
			}
		}
		for param in params {
			method['params'] << map[string]Any{
				'name': param.name,
				'description': 'Parameter $param.name of type $param.type',
				'schema': get_type_schema(param.type)
			}
		}
		openrpc_spec['methods'] << method
	}

	return openrpc_spec
}

// fn main() {
// 	openrpc_spec := parser(path: '~/code/git.ourworld.tf/projectmycelium/hero_server/generatorexamples/example1/specs')
// 	json_out := json.encode_pretty(openrpc_spec)
// 	yaml_out := yaml.encode(openrpc_spec)

// 	json_filename := '/tmp/openrpc_spec.json'
// 	os.write_file(json_filename, json_out) or { panic(err) }
// 	println('OpenRPC specification (JSON) has been written to: $json_filename')

// 	yaml_filename := '/tmp/openrpc_spec.yaml'
// 	os.write_file(yaml_filename, yaml_out) or { panic(err) }
// 	println('OpenRPC specification (YAML) has been written to: $yaml_filename')
// }
