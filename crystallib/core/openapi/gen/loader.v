module gen

struct Loader{
	spec openapi.OpenAPI
	structs map[string]codemodel.Struct
}

fn (mut l Loader) load_schema(struct_name string, schema openapi.Schema){
	// load codemodle struct form openapi schema
	// should have a type of object
	current_struct := codemodel.Struct{
		name: struct_name
	}

	for name, prop in schema.properties{
		if prop.type_ == 'object'{
			field_type_name := '${struct_name}${name.capitalize()}'
			_strct := l.load_schema(field_type_name, prop)
			l.structs[field_type_name] = _strct
			current_struct.fields << load_struct_field_object(name, field_type_name, prop)
			continue
		}

		current_struct.fields << load_struct_field(name, schema)
	}
}

// loads a struct field of primitive type (string, float64, u64, ...) from an openapi.Schema
fn load_struct_field(field_name string, schema openapi.Schema) codemodel.StructField{
	return codemodel.StructField{
		name: field_name
		typ: codemodel.Type{
			symbol: get_type_symbol_from_schema(schema.type_, schema.format)
		}
	}
}

// loads a struct field of an object type from an openapi.Schema
load_struct_field_object(field_name string, struct_name string, schema.openapi.Schema) codemodel.StructField{
	return codemodel.StructField{
		name: field_name
		typ: codemodel.Type{
			symbol: get_type_symbol_from_schema(schema.type_, struct_name)
		}
	}
}

fn get_type_symbol_from_schema(type_ string, format string) string{
	// get type name
	if type_ == 'object'{
		return format
	}

	if type_ == 'string'{
		return type_
	}

	if type_ == 'number' && format == 'float'{
		return 'float64'
	}

	if type_ == 'number' && format == 'integer'{
		return 'u64'
	}
}

fn (mut l Loader) load_components_structs(components openapi.Components){
	// load codemodel structs from openapi spec
	for k, v in components.schemas{
		l.load_schema(k, v)
	}
}

/*
	pub struct Operation {
	mut:
		tags          ?[]string //	A list of tags for API documentation control. Tags can be used for logical grouping of operations by resources or any other qualifier.
		summary       ?string   //	A short summary of what the operation does.
		description   ?string   // A verbose explanation of the operation behavior. CommonMark syntax MAY be used for rich text representation.
		external_docs ?ExternalDocumentation  @[json: 'externalDocs'] // Additional external documentation for this operation.
		operation_id  ?string                 @[json: 'operationId'] // Unique string used to identify the operation. The id MUST be unique among all operations described in the API. The operationId value is case-sensitive. Tools and libraries MAY use the operationId to uniquely identify an operation, therefore, it is RECOMMENDED to follow common programming naming conventions.
		parameters    ?[]Parameter // A list of parameters that are applicable for this operation. If a parameter is already defined at the Path Item, the new definition will override it but can never remove it. The list MUST NOT include duplicated parameters. A unique parameter is defined by a combination of a name and location. The list can use the Reference Object to link to parameters that are defined at the OpenAPI Object’s components/parameters.
		request_body  ?RequestRef             @[json: 'requestBody'] // The request body applicable for this operation. The requestBody is fully supported in HTTP methods where the HTTP 1.1 specification [RFC7231] has explicitly defined semantics for request bodies. In other cases where the HTTP spec is vague (such as GET, HEAD and DELETE), requestBody is permitted but does not have well-defined semantics and SHOULD be avoided if possible.
		responses     ?map[string]ResponseRef // The list of possible responses as they are returned from executing this operation.
		callbacks     ?map[string]CallbackRef // A map of possible out-of band callbacks related to the parent operation. The key is a unique identifier for the Callback Object. Each value in the map is a Callback Object that describes a request that may be initiated by the API provider and the expected responses.
		deprecated    ?bool // Declares this operation to be deprecated. Consumers SHOULD refrain from usage of the declared operation. Default value is false.
		security      ?[]SecurityRequirement //	A declaration of which security mechanisms can be used for this operation. The list of values includes alternative security requirement objects that can be used. Only one of the security requirement objects need to be satisfied to authorize a request. To make security optional, an empty security requirement ({}) can be included in the array. This definition overrides any declared top-level security. To remove a top-level security declaration, an empty array can be used.
		servers       ?[]Server // An alternative server array to service this operation. If an alternative server object is specified at the Path Item Object or Root level, it will be overridden by this value.
	}
*/

fn (mut l Loader) load_operation(method http.Method, operation openapi.Operation) []codemodel.CodeItem{
	// load codemodel function from openapi operation
	
}


// 

/*
	pub struct Struct {
	pub mut:
		name        string
		description string
		mod         string
		is_pub      bool
		attrs       []Attribute
		fields      []StructField
	}

	pub struct Schema {
		type_       string            @[json: 'type']
		description string
		enum_       []string          @[json: 'enum']
		properties  map[string]Schema
		format      string
		ref         string            @[json: "\$ref"]
		example     string
		nullable    bool
		required    ?[]string
	}

	pub struct StructField {
	pub:
		comments    []Comment
		attrs       []Attribute
		name        string
		description string
		default     string
		is_pub      bool
		is_mut      bool
		anon_struct Struct // sometimes fields may hold anonymous structs
		typ         Type
	pub mut:
		structure Struct
	}

	pub struct Type {
	pub:
		is_reference bool
		is_map       bool
		is_array     bool
		is_mutable   bool
		is_shared    bool
		is_optional  bool
		is_result    bool
		symbol       string
		mod          string
	}
*/