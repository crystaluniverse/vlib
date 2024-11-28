module gen

import net.http
import freeflowuniverse.crystallib.core.codemodel { Struct, StructField, Type }

fn test_generate_client() {
	mut gen := ClientGenerator{
		api_name: 'testapi'
		client_struct: Struct{
			name: '${'testapi'.title()}Client'
		}
	}
	client_file := gen.generate_client()
	assert client_file.name == 'client'
	assert client_file.mod == 'testapi_client'
	assert client_file.imports == []
	assert client_file.items[0] is Struct
	assert (client_file.items[0] as Struct).name == 'TestapiClient'
}

fn test_generate_model() {
	mut gen := ClientGenerator{
		api_name: 'testapi'
		client_struct: Struct{
			name: '${'testapi'.title()}Client'
		}
	}
	model_file := gen.generate_model([
		Struct{
			name: 'SomeModel'
			fields: [
				StructField{
					name: 'text'
					typ: Type{
						symbol: 'string'
					}
				},
			]
		},
	])!
	assert model_file.name == 'model'
	assert model_file.mod == 'testapi_client'
	assert model_file.imports == []
	assert model_file.items[0] is Struct
	assert (model_file.items[0] as Struct).name == 'SomeModel'
}

// fn (mut gen ClientGenerator) generate_model(structs []Struct) !CodeFile {
// 	return CodeFile{
// 		name: 'model'
// 		items: structs.map(CodeItem(it))
// 	}
// }

// fn (mut gen ClientGenerator) generate_methods(paths []Path) !CodeFile {
// 	mut code := []CodeItem{}
// 	for path in paths {
// 		for operation in path.operations {
// 			structs := operation.parameters.map(it.Param.struct_)
// 			to_generate := structs.filter(it !in gen.generated_structs)
// 			code << gen.generate_method_structs(to_generate)
// 			code << gen.generate_client_method()!
// 		}
// 	}
// 	return CodeFile{
// 		name: 'methods'
// 		items: code
// 	}
// }

// fn (mut gen ClientGenerator) generate_method_structs(structs []Struct) []Struct {
// 	gen.generated_structs << structs
// 	return structs
// }

// [params]
// pub struct ClientMethodConfig {
// 	receiver   codemodel.Param
// 	name       string // name of method
// 	parameters []Parameter
// 	responses  map[string]Parameter // Params mapped by http response code
// 	method     http.Method
// }

// // generate_client_call generates a client method and accompanying necessary
// pub fn (mut gen ClientGenerator) generate_client_method(config ClientMethodConfig) !codemodel.Function {
// 	// http_request :=

// 	if '200' !in config.responses {
// 		return error('At least one response should have a 200 http code')
// 	}

// 	result_struct := config.responses['200'].struct_

// 	result := codemodel.Result{
// 		name: result_struct.name
// 		structure: config.responses['200'].Param.struct_
// 		typ: Type{
// 			symbol: result_struct.name
// 		}
// 	}

// 	return codemodel.Function{
// 		name: config.name
// 		receiver: config.receiver
// 		params: config.parameters.map(it.Param)
// 		result: result
// 	}
// }
