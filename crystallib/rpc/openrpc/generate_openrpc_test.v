module openrpc

import os
import freeflowuniverse.crystallib.core.codemodel
import freeflowuniverse.crystallib.data.jsonschema

// test_fn_to_method tests whether
fn test_params_to_descriptors() {
	// testing only a few types of parameters since
	// an exhaustive type_to_schema test is done at jsonschema/schema_test.v
	params := [
		codemodel.Param{
			name:        'test_param'
			description: 'a parameter to test if params are also included in the method description.'
			required:    true
			typ:         codemodel.Type{
				symbol: 'string'
			}
		},
		codemodel.Param{
			name:        'another_param'
			description: 'a second parameter to test if method description works with multiple params.'
			typ:         codemodel.Type{
				symbol: 'int'
			}
		},
		codemodel.Param{
			name: 'array_param'
			typ:  codemodel.Type{
				symbol: '[]string'
			}
		},
		codemodel.Param{
			name: 'object_param'
			typ:  codemodel.Type{
				symbol: 'Object'
			}
		},
	]

	descriptors := params_to_descriptors(params)

	// test test_param is described correctly
	assert descriptors[0] is ContentDescriptor
	param0 := descriptors[0] as ContentDescriptor
	assert param0.name == 'test_param'
	param0_description := param0.description or { '' }
	assert param0_description == 'a parameter to test if params are also included in the method description.'
	// param0_required := param
	assert param0.required or { false } == true
	assert param0.schema is jsonschema.Schema
	param0_schema := param0.schema as jsonschema.Schema
	assert param0_schema.typ == 'string'

	// test another_param is described correctly
	assert descriptors[1] is ContentDescriptor
	param1 := descriptors[1] as ContentDescriptor
	assert param1.name == 'another_param'
	param1_description := param1.description or { '' }
	assert param1_description == 'a second parameter to test if method description works with multiple params.'
	assert param1.schema is jsonschema.Schema
	param1_schema := param1.schema as jsonschema.Schema
	assert param1_schema.typ == 'integer'

	// test array_param is described correctly
	assert descriptors[2] is ContentDescriptor
	param2 := descriptors[2] as ContentDescriptor
	assert param2.name == 'array_param'
	assert param2.schema is jsonschema.Schema
	param2_schema := param2.schema as jsonschema.Schema
	assert param2_schema.typ == 'array'
	assert param2_schema.items is jsonschema.SchemaRef
	mut param2_schema_items := param2_schema.items as jsonschema.SchemaRef
	assert param2_schema_items is jsonschema.Schema
	param2_schema_items_schema := param2_schema_items as jsonschema.Schema
	assert param2_schema_items_schema.typ == 'string'

	// test object_param is described correctly
	assert descriptors[3] is ContentDescriptor
	param3 := descriptors[3] as ContentDescriptor
	assert param3.name == 'object_param'
	// should be reference since the param type is a struct
	assert param3.schema is jsonschema.Reference
	param3_schema := param3.schema as jsonschema.Reference
	assert param3_schema.ref == '#/components/schemas/Object'
}

// test_fn_to_method tests whether
fn test_fn_to_method() {
	function := codemodel.Function{
		name:        'test_function'
		description: 'tests whether OpenRPC method description can be generated from function.'
		// testing only with single simple param since params_to_descriptors is tested above
		params:     [
			codemodel.Param{
				name: 'test_param'
				typ:  codemodel.Type{
					symbol: 'string'
				}
			},
		]
		has_return: true
		result:     codemodel.Result{
			name:        'string_list'
			description: 'a list of strings which the function will return'
			typ:         codemodel.Type{
				symbol: '[]string'
			}
		}
	}

	openrpc_method := fn_to_method(function)

	// test method info is described correctly
	assert openrpc_method.name == 'TestFunction'
	description := openrpc_method.description or { '' }
	assert description == 'tests whether OpenRPC method description can be generated from function.'
	assert openrpc_method.params.len == 1

	// test test_param is described correctly
	assert openrpc_method.params[0] is ContentDescriptor
	param0 := openrpc_method.params[0] as ContentDescriptor
	assert param0.name == 'test_param'
	assert param0.schema is jsonschema.Schema
	param0_schema := param0.schema as jsonschema.Schema
	assert param0_schema.typ == 'string'

	// test function return is described correctly
	assert openrpc_method.result is ContentDescriptor
	result := openrpc_method.result as ContentDescriptor
	assert result.name == 'string_list'
	assert result.description or { '' } == 'a list of strings which the function will return'
	assert result.schema is jsonschema.Schema
	result_schema := result.schema as jsonschema.Schema
	assert result_schema.typ == 'array'
	assert result_schema.items is jsonschema.SchemaRef
	mut result_schema_items := result_schema.items as jsonschema.SchemaRef
	assert result_schema_items is jsonschema.Schema
	result_schema_items_schema := result_schema_items as jsonschema.Schema
	assert result_schema_items_schema.typ == 'string'
}

// test_docgen tests whether OpenRPC document generation for the PetStore JSON-RPC Client
// works across different configurations
fn test_docgen() ! {
	client_path := os.dir(@FILE) + '/testdata/petstore_client'
	doc := docgen(
		title:  'test'
		source: client_path
	)!
	// assert doc == {}
}
