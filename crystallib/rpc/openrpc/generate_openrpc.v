module openrpc

import freeflowuniverse.crystallib.data.jsonschema
import freeflowuniverse.crystallib.core.codemodel { Function, Struct, Sumtype }
import freeflowuniverse.crystallib.core.codeparser
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.texttools

// configuration parameters for OpenRPC Document generation.
@[params]
pub struct DocGenConfig {
	title         string // Title of the JSON-RPC API
	description   string // Description of the JSON-RPC API
	version       string = '1.0.0' // OpenRPC Version used
	source        string   // Source code directory to generate doc from
	strict        bool     // Strict mode generates document for only methods and struct with the attribute `openrpc`
	exclude_dirs  []string // directories to be excluded when parsing source for document generation
	exclude_files []string // files to be excluded when parsing source for document generation
	only_pub      bool     // excludes all non-public declarations from document generation
}

// docgen returns OpenRPC Document struct for JSON-RPC API defined in the config params.
// returns generated OpenRPC struct which can be encoded into json using `OpenRPC.encode()`
pub fn docgen(config DocGenConfig) !OpenRPC {
	$if debug {
		console.print_debug('Generating OpenRPC Document from path: ${config.source}')
	}

	// parse source code into code items
	code := codeparser.parse_v(config.source,
		exclude_dirs:  config.exclude_dirs
		exclude_files: config.exclude_files
		only_pub:      config.only_pub
		recursive:     true
	)!

	mut schemas := map[string]jsonschema.SchemaRef{}
	mut methods := []Method{}

	// generate JSONSchema compliant schema definitions for structs in code
	for struct_ in code.filter(it is Struct).map(it as Struct) {
		schema := jsonschema.struct_to_schema(struct_)
		schemas[struct_.name] = schema
	}

	// generate JSONSchema compliant schema definitions for sumtypes in code
	for sumtype in code.filter(it is Sumtype).map(it as Sumtype) {
		schema := jsonschema.sumtype_to_schema(sumtype)
		schemas[sumtype.name] = schema
	}

	// generate OpenRPC compliant method definitions for functions in code
	for function in code.filter(it is Function).map(it as Function) {
		method := fn_to_method(function)
		methods << method
	}

	return OpenRPC{
		info:       Info{
			title:   config.title
			version: config.version
		}
		methods:    methods
		components: Components{
			schemas: schemas
		}
	}
}

// fn_to_method turns a codemodel function into a openrpc method description
pub fn fn_to_method(function Function) Method {
	$if debug {
		console.print_debug('Creating openrpc method description for function: ${function.name}')
	}

	params := params_to_descriptors(function.params)
	// if result name isn't set, set it to
	result_name := if function.result.name != '' {
		function.result.name
	} else {
		function.result.typ.symbol
	}

	// result := ContentDescriptor{
	// 	name: result_name
	// 	schema: result_schema
	// 	description: function.result.description
	// }

	pascal_name := texttools.name_fix_snake_to_pascal(function.name)
	function_name := if function.mod != '' {
		'${pascal_name}'
	} else {
		pascal_name
	}
	m := Method{
		name:        function_name
		description: function.description
		params:      params
		result:      result_to_descriptor(function.result)
	}

	return Method{
		name:        function_name
		description: function.description
		params:      params
		result:      result_to_descriptor(function.result)
	}
}

// get_param_descriptors returns content descriptors generated for a list of params
fn params_to_descriptors(params []codemodel.Param) []ContentDescriptorRef {
	mut descriptors := []ContentDescriptorRef{}
	for param in params {
		descriptors << param_to_descriptor(param)
	}
	return descriptors
}

// get_param_descriptors returns content descriptors generated for a list of params
fn param_to_descriptor(param codemodel.Param) ContentDescriptorRef {
	schemaref := jsonschema.param_to_schema(param)
	return ContentDescriptorRef(ContentDescriptor{
		name:        param.name
		schema:      schemaref
		description: param.description
		required:    param.required
	})
}

// get_param_descriptors returns content descriptors generated for a list of params
pub fn result_to_descriptor(result codemodel.Result) ContentDescriptorRef {
	schemaref := jsonschema.result_to_schema(result)

	name := if result.name != '' {
		result.name
	} else if result.typ.symbol != '' {
		result.typ.symbol
	} else {
		'null'
	}
	return ContentDescriptorRef(ContentDescriptor{
		name:        name
		schema:      schemaref
		description: result.description
	})
}
