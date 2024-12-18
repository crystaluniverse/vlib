module jsonschema

import freeflowuniverse.crystallib.core.codemodel { Param, Result, Struct, Type }

// struct_to_schema generates a json schema or reference from a struct model
pub fn sumtype_to_schema(sumtype codemodel.Sumtype) SchemaRef {
	mut one_of := []SchemaRef{}
	for type_ in sumtype.types {
		property_schema := typesymbol_to_schema(type_.symbol)
		one_of << property_schema
	}

	title := sumtype.name

	return SchemaRef(Schema{
		title:       title
		description: sumtype.description
		one_of:      one_of
	})
}

// struct_to_schema generates a json schema or reference from a struct model
pub fn struct_to_schema(struct_ Struct) SchemaRef {
	mut properties := map[string]SchemaRef{}
	for field in struct_.fields {
		mut property_schema := SchemaRef(Schema{})
		if field.typ.symbol.starts_with('_VAnonStruct') {
			property_schema = struct_to_schema(field.anon_struct)
		} else {
			property_schema = type_to_schema(field.typ)
		}
		if mut property_schema is Schema {
			properties[field.name] = SchemaRef(Schema{
				...property_schema
				description: field.description
			})
		} else {
			properties[field.name] = property_schema
		}
	}

	title := if struct_.name.starts_with('_VAnonStruct') {
		''
	} else {
		struct_.name
	}

	return SchemaRef(Schema{
		title:       title
		description: struct_.description
		properties:  properties
	})
}

pub fn param_to_schema(param Param) SchemaRef {
	if param.struct_ != Struct{} {
		return struct_to_schema(param.struct_)
	}
	return typesymbol_to_schema(param.typ.symbol)
}

pub fn result_to_schema(result Result) SchemaRef {
	if result.structure != Struct{} {
		return struct_to_schema(result.structure)
	}
	return typesymbol_to_schema(result.typ.symbol)
}

// typesymbol_to_schema receives a typesymbol, if the typesymbol belongs to a user defined struct
// it returns a reference to the schema, else it returns a schema for the typesymbol
pub fn typesymbol_to_schema(symbol_ string) SchemaRef {
	mut symbol := symbol_.trim_string_left('!').trim_string_left('?')
	if symbol == '' {
		return SchemaRef(Schema{
			typ: 'null'
		})
	} else if symbol.starts_with('[]') {
		mut array_type := symbol.trim_string_left('[]')
		return SchemaRef(Schema{
			typ:   'array'
			items: typesymbol_to_schema(array_type)
		})
	} else if symbol.starts_with('map[string]') {
		mut map_type := symbol.trim_string_left('map[string]')
		return SchemaRef(Schema{
			typ:                   'object'
			additional_properties: typesymbol_to_schema(map_type)
		})
	} else if symbol[0].is_capital() {
		// todo: better imported type handling
		if symbol == 'Uint128' {
			return SchemaRef(Schema{
				typ:     'integer'
				minimum: Number(0)
				// todo: implement uint128 number
				// maximum: Number('340282366920938463463374607431768211455')
			})
		}
		return SchemaRef(Reference{
			ref: '#/components/schemas/${symbol}'
		})
	} else if symbol.starts_with('_VAnonStruct') {
		return SchemaRef(Reference{
			ref: '#/components/schemas/${symbol}'
		})
	} else {
		if symbol == 'void' {
			return SchemaRef(Schema{
				typ: 'null'
			})
		}
		if symbol == 'bool' {
			return SchemaRef(Schema{
				typ: 'boolean'
			})
		}
		if symbol == 'int' {
			return SchemaRef(Schema{
				typ: 'integer'
			})
		}
		if symbol == 'u8' {
			return SchemaRef(Schema{
				typ: 'integer'
			})
		}
		if symbol == 'u16' {
			return SchemaRef(Schema{
				typ: 'integer'
			})
		}
		if symbol == 'u32' {
			return SchemaRef(Schema{
				typ: 'integer'
			})
		}
		if symbol == 'u64' {
			return SchemaRef(Schema{
				typ: 'string'
			})
		}
		if symbol == 'f32' {
			return SchemaRef(Schema{
				typ: 'string'
			})
		}
		if symbol == 'f64' {
			return SchemaRef(Schema{
				typ: 'string'
			})
		}
		if symbol == '!' {
			return SchemaRef(Schema{
				typ: 'null'
			})
		}
		if symbol == 'i64' {
			return SchemaRef(Schema{
				typ: 'string'
			})
		}
		if symbol == 'byte' {
			return SchemaRef(Schema{
				typ: 'string'
			})
		}
		return SchemaRef(Schema{
			typ: symbol
		})
	}
}

pub fn type_to_schema(typ Type) SchemaRef {
	mut symbol := typ.symbol.trim_string_left('!').trim_string_left('?')
	if symbol == '' {
		return SchemaRef(Schema{
			typ: 'null'
		})
	} else if symbol.starts_with('[]') || typ.is_array {
		mut array_type := symbol.trim_string_left('[]')
		return SchemaRef(Schema{
			typ:   'array'
			items: typesymbol_to_schema(array_type)
		})
	} else if symbol.starts_with('map[string]') {
		mut map_type := symbol.trim_string_left('map[string]')
		return SchemaRef(Schema{
			typ:                   'object'
			additional_properties: typesymbol_to_schema(map_type)
		})
	} else if symbol[0].is_capital() {
		// todo: better imported type handling
		if symbol == 'Uint128' {
			return SchemaRef(Schema{
				typ:     'integer'
				minimum: Number(0)
				// todo: implement uint128 number
				// maximum: Number('340282366920938463463374607431768211455')
			})
		}
		return SchemaRef(Reference{
			ref: '#/components/schemas/${symbol}'
		})
	} else if symbol.starts_with('_VAnonStruct') {
		return SchemaRef(Reference{
			ref: '#/components/schemas/${symbol}'
		})
	} else {
		if symbol == 'void' {
			return SchemaRef(Schema{
				typ: 'null'
			})
		}
		if symbol == 'bool' {
			return SchemaRef(Schema{
				typ: 'boolean'
			})
		}
		if symbol == 'int' {
			return SchemaRef(Schema{
				typ: 'integer'
			})
		}
		if symbol == 'u8' {
			return SchemaRef(Schema{
				typ: 'integer'
			})
		}
		if symbol == 'u16' {
			return SchemaRef(Schema{
				typ: 'integer'
			})
		}
		if symbol == 'u32' {
			return SchemaRef(Schema{
				typ: 'integer'
			})
		}
		if symbol == 'u64' {
			return SchemaRef(Schema{
				typ: 'string'
			})
		}
		if symbol == 'f64' {
			return SchemaRef(Schema{
				typ: 'string'
			})
		}
		if symbol == '!' {
			return SchemaRef(Schema{
				typ: 'null'
			})
		}
		if symbol == 'i64' {
			return SchemaRef(Schema{
				typ: 'string'
			})
		}
		if symbol == 'byte' {
			return SchemaRef(Schema{
				typ: 'string'
			})
		}
		return SchemaRef(Schema{
			typ: symbol
		})
	}
}
