module openapi

import json
import x.json2 { Any }
import freeflowuniverse.crystallib.data.jsonschema

pub fn json_decode(data string) !OpenAPI {
	// Decode the raw JSON into a map to allow field-specific processing
	raw_map := json2.raw_decode(data)!.as_map()

	// Decode the entire OpenAPI structure using standard JSON decoding
	mut spec := json.decode(OpenAPI, data)!

	// Decode all schema and schemaref fields using `jsonschema.decode_schemaref`
	// 1. Process components.schemas
	if 'paths' in raw_map {
		mut paths := raw_map['paths'].as_map()
		for key, path in paths {
			spec.paths[key] = json_decode_path(spec.paths[key], path.as_map())!
		}
	}

	if 'components' in raw_map {
		components_map := raw_map['components'].as_map()
		spec.components = json_decode_components(spec.components, components_map)!
	}

	// Return the fully decoded OpenAPI structure
	return spec
}

pub fn json_decode_components(components_ Components, components_map map[string]Any) !Components {
	mut components := components_

	if 'schemas' in components_map {
		components.schemas = jsonschema.decode_schemaref_map(components_map['schemas'].as_map())!
	}
	return components
}

pub fn json_decode_path(path_ PathItem, path_map map[string]Any) !PathItem {
	mut path := path_

	for key in path_map.keys() {
		match key {
			'get' {
				operation_map := path_map[key].as_map()
				path.get = json_decode_operation(path.get, operation_map)!
			}
			'post' {
				operation_map := path_map[key].as_map()
				path.post = json_decode_operation(path.post, operation_map)!
			}
			'put' {
				operation_map := path_map[key].as_map()
				path.put = json_decode_operation(path.put, operation_map)!
			}
			'delete' {
				operation_map := path_map[key].as_map()
				path.delete = json_decode_operation(path.delete, operation_map)!
			}
			'options' {
				operation_map := path_map[key].as_map()
				path.options = json_decode_operation(path.options, operation_map)!
			}
			'head' {
				operation_map := path_map[key].as_map()
				path.head = json_decode_operation(path.head, operation_map)!
			}
			'patch' {
				operation_map := path_map[key].as_map()
				path.patch = json_decode_operation(path.patch, operation_map)!
			}
			'trace' {
				operation_map := path_map[key].as_map()
				path.trace = json_decode_operation(path.trace, operation_map)!
			}
			else {
				continue
			}
		}
	}
	return path
}

pub fn json_decode_operation(operation_ Operation, operation_map map[string]Any) !Operation {
	mut operation := operation_

	if 'requestBody' in operation_map {
		request_body_any := operation_map['requestBody']
		request_body_map := request_body_any.as_map()

		if 'content' in request_body_map {
			mut request_body := json.decode(RequestBody, request_body_any.str())!
			// mut request_body := operation.request_body as RequestBody
			mut content := request_body.content.clone()
			content_map := request_body_map['content'].as_map()
			request_body.content = json_decode_content(content, content_map)!
			operation.request_body = request_body
		}
	}

	if 'responses' in operation_map {
		responses_map := operation_map['responses'].as_map()
		for key, response_any in responses_map {
			response_map := response_any.as_map()
			if 'content' in response_map {
				mut response := operation.responses[key]
				mut content := response.content.clone()
				content_map := response_map['content'].as_map()
				response.content = json_decode_content(content, content_map)!
				operation.responses[key] = response
			}
		}
	}

	if 'parameters' in operation_map {
		parameters_arr := operation_map['parameters'].arr()
		mut parameters := []Parameter{}
		for i, parameter_any in parameters_arr {
			parameter_map := parameter_any.as_map()
			if 'schema' in parameter_map {
				mut parameter := operation.parameters[i]
				parameter.schema = jsonschema.decode_schemaref(parameter_map['schema'].as_map())!
				parameters << parameter
			} else {
				parameters << operation.parameters[i]
			}
		}
		operation.parameters = parameters
	}

	return operation
}

fn json_decode_content(content_ map[string]MediaType, content_map map[string]Any) !map[string]MediaType {
	mut content := content_.clone()
	for key, item in content_map {
		media_type_map := item.as_map()
		schema_any := media_type_map['schema']
		mut media_type := content[key]
		media_type.schema = jsonschema.decode_schemaref(schema_any.as_map())!
		content[key] = media_type
	}
	return content
}

// pub fn json_decode(data string) !OpenAPI {
// 	// Decode the raw JSON into the OpenAPI structure
// 	mut spec := json.decode(OpenAPI, data)!

// 	data_map := json2.raw_decode(data)!.as_map()

// 	// Recursively process the structure to decode SchemaRef and Schema fields
// 	spec = decode_recursive(spec, data_map)!

// 	return spec
// }

// fn decode_recursive[T](obj T, data_map map[string]Any) !T {
// 	// data_map := json2.raw_decode(data)!.as_map()

// 	$for field in T.fields {
// 		$if field.is_array {
// 			val := obj.$(field.name)
// 			field_array := data_map[field.name].arr()
// 			// mut data_fmt := data.replace(action_str, '')
// 			// data_fmt = data.replace('define.${obj_name}', 'define')
// 			arr := decode_array(val, field_array)!
// 			obj.$(field.name) = arr
// 		}

// 		println('field ${field.name} ${typeof(field.typ)}')
// 		field_map := data_map[field.name].as_map()
// 		// Check if the field is of type Schema or SchemaRef
// 		$if field.typ is SchemaRef {
// 			obj.$(field.name) = jsonschema.decode_schemaref(field_map)!
// 		} $else $if field.typ is map[string]SchemaRef {
// 			// Check if the field is a map with SchemaRef or Schema as values
// 			obj.$(field.name) = jsonschema.decode_schemaref_map(field_map)!
// 		} $else {
// 			val := obj.$(field.name)
// 			obj.$(field.name) = decode_recursive(val, field_map)!
// 		}
// 	}

// 	return obj
// }

// pub fn decode_array[T](_ []T, data_arr []Any) ![]T {
// 	mut arr := []T{}
// 	for data in data_arr {
// 		value := T{}
// 		$if T is $struct {
// 			arr << decode_recursive(value, data.as_map())!
// 		} $else {
// 			arr << value
// 		}
// 	}
// 	return arr
// }

fn (o OpenAPI) json_encode() string {
	return json.encode(o).replace('ref', '\$ref')
}
