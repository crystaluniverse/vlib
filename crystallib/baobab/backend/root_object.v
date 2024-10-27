module backend

import x.json2


// describes a root object
pub struct RootObject {
pub mut:
	id string
	name string // Story
	fields []FieldDescription
}

pub struct FieldDescription {
pub mut:
	name string // name of field
	typ FieldType
	value string // value of field
	is_secret bool // whether field should be encrypted upon storage
	is_index bool // whether object is searchable by field
	fts_enabled bool // whether full text search on field is enabled
}

// returns the sql type name of the field
pub fn (field FieldDescription) sql_type() string {
	return match field.typ {
		.text {'TEXT'}
		.number {'INTEGER'}
	}
}

pub enum FieldType {
	number
	text
}

pub fn (obj RootObject) to_json() string {
	mut obj_map := map[string]json2.Any
	for field in obj.fields {
		obj_map[field.name] = field.value
	}

	return obj_map.str()
}


// returns the lists of the indices of a root objects db table, and corresponding values
pub fn (obj RootObject) sql_indices_values() ([]string, []string) {
	obj_encoded := obj.to_json()
	obj_val := "'${obj_encoded.replace("'", "''")}'"

	// insert root object into its table
	mut indices := ['data']
	mut values := [obj_val]

	for field in obj.fields {
		if field.name == 'id' {
			indices << '${field.name}'
			values << "${field.value}"
		}

		if field.typ == .text {
			if field.is_index {
				indices << '${field.name}'
				values << "'${field.value}'"
			}
		} else if field.typ == .number {
			if field.is_index {
				indices << '${field.name}'
				values << "${field.value}"
			}
		}
	}
	println('debugzoni ${indices} ${values}')
	return indices, values

}

// return the description of a given generic
pub fn root_object[T](object T) RootObject {
	mut fields := []FieldDescription{}

	$for field in T.fields {
		mut typ := FieldType{}
		$if field.typ is string {
			typ = .text
		} $else $if field.typ is int {
			typ = .number
		}

		fields << FieldDescription{
			name: field.name
			typ: typ
			value: object.$(field.name).str()
			is_index: field.attrs.contains('index')
			is_secret: field.attrs.contains('secret')
			fts_enabled: field.attrs.contains('fts_enabled')
		}
	}

	return RootObject {
		name: typeof[T]()
		fields: fields
	}
}

// decodes root object into generic struct T
pub fn (object RootObject) to_generic[T]() T {
	mut t := T{}

	$for field in T.fields {
		field_descrs := object.fields.filter(it.name == field.name)
		if field_descriptions.len == 1 {
			t.$(field.name) = field_descrs[0].value
		}
	}
	return t
}

pub fn root_object_from_json(json string) !RootObject {
	raw_decode := json2.raw_decode(json)!
	obj_map := raw_decode.as_map()

	mut obj := RootObject{}
	for key, val in obj_map {
		obj.fields << FieldDescription {
			name: key
			value: val.str()
		}
	}

	return obj

}