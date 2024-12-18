module jsonschema

import freeflowuniverse.crystallib.core.codemodel { Alias, Attribute, CodeItem, Struct, StructField, Type }

const vtypes = {
	'integer': 'int'
	'string':  'string'
}

pub fn (schema Schema) v_encode() !string {
	module_name := 'schema.title.'
	structs := schema.vstructs_encode()!
	// todo: report bug: return $tmpl(...)
	encoded := $tmpl('templates/schema.vtemplate')
	return encoded
}

// vstructs_encode encodes a schema into V structs.
// if a schema has nested object type schemas or defines object type schemas,
// recrusively encodes object type schemas and pushes to the array of structs.
// returns an array of schemas that have been encoded into V structs.
pub fn (schema Schema) vstructs_encode() ![]string {
	mut schemas := []string{}
	mut properties := ''

	// loop over properties
	for name, property_ in schema.properties {
		mut property := Schema{}
		mut typesymbol := ''

		if property_ is Reference {
			// if reference, set typesymbol as reference name
			ref := property_ as Reference
			typesymbol = ref.ref.all_after_last('/')
		} else {
			property = property_ as Schema
			typesymbol = property.vtype_encode()!
			// recursively encode property if object
			// todo: handle duplicates
			if property.typ == 'object' {
				structs := property.vstructs_encode()!
				schemas << structs
			}
		}

		properties += '\n\t${name} ${typesymbol}'
		if name in schema.required {
			properties += ' @[required]'
		}
	}
	schemas << $tmpl('templates/struct.vtemplate')
	return schemas
}

// code_type generates a typesymbol for the schema
pub fn (schema Schema) vtype_encode() !string {
	mut property_str := ''
	if schema.typ == 'null' {
		return ''
	}
	if schema.typ == 'object' {
		if schema.title == '' {
			return error('Object schemas must define a title.')
		}
		// todo: enfore uppercase
		property_str = schema.title
	} else if schema.typ == 'array' {
		// todo: handle multiple item schemas
		if schema.items is SchemaRef {
			// items := schema.items as SchemaRef
			if schema.items is Schema {
				items_schema := schema.items as Schema
				property_str = '[]${items_schema.typ}'
			}
		}
	} else if schema.typ in vtypes.keys() {
		property_str = vtypes[schema.typ]
	} else if schema.title != '' {
		property_str = schema.title
	} else {
		return error('unknown type `${schema.typ}` ')
	}
	return property_str
}

pub fn (schema Schema) to_code() !CodeItem {
	if schema.typ == 'object' {
		return CodeItem(schema.to_struct()!)
	}
	if schema.typ in vtypes {
		return Alias{
			name: schema.title
			typ:  Type{
				symbol: vtypes[schema.typ]
			}
		}
	}
	if schema.typ == 'array' {
		if schema.items is SchemaRef {
			if schema.items is Schema {
				items_schema := schema.items as Schema
				return Alias{
					name: schema.title
					typ:  Type{
						symbol: '[]${items_schema.typ}'
					}
				}
			} else if schema.items is Reference {
				items_ref := schema.items as Reference
				return Alias{
					name: schema.title
					typ:  Type{
						symbol: '[]${items_ref.to_type_symbol()}'
					}
				}
			}
		}
	}
	return error('Schema typ ${schema.typ} not supported for code generation')
}

pub fn (schema Schema) to_struct() !Struct {
	mut fields := []StructField{}

	for key, val in schema.properties {
		mut field := val.to_struct_field(key)!
		if field.name in schema.required {
			field.attrs << Attribute{
				name: 'required'
			}
		}
		fields << field
	}

	return Struct{
		name:        schema.title
		description: schema.description
		fields:      fields
	}
}

pub fn (schema SchemaRef) to_struct_field(name string) !StructField {
	if schema is Reference {
		return StructField{
			name: name
			typ:  Type{
				symbol: schema.to_type_symbol()
			}
		}
	} else if schema is Schema {
		mut field := StructField{
			name:        name
			description: schema.description
		}
		if schema.typ == 'object' {
			// then is anonymous struct
			field.anon_struct = schema.to_struct()!
			return field
		} else if schema.typ in vtypes {
			field.typ.symbol = vtypes[schema.typ]
			return field
		}
		return error('Schema typ ${schema.typ} not supported for code generation')
	}
	return error('Schema typ  not supported for code generation')
}

pub fn (sr SchemaRef) to_code() !Type {
	return if sr is Reference {
		sr.to_type()
	} else {
		Type{
			symbol: (sr as Schema).vtype_encode()!
		}
	}
}

pub fn (ref Reference) to_type_symbol() string {
	return ref.ref.all_after_last('/')
}

pub fn (ref Reference) to_type() Type {
	return Type{
		symbol: ref.to_type_symbol()
	}
}
