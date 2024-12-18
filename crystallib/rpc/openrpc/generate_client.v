module openrpc

import freeflowuniverse.crystallib.core.codemodel { CodeFile, CodeItem, CustomCode, Function, Struct, parse_function }
import freeflowuniverse.crystallib.data.jsonschema
import freeflowuniverse.crystallib.rpc.jsonrpc
import freeflowuniverse.crystallib.core.texttools

// generate_structs geenrates struct codes for schemas defined in an openrpc document
pub fn (o OpenRPC) generate_client_file(object_map map[string]Struct) !CodeFile {
	name := texttools.name_fix(o.info.title)
	client_struct_name := '${o.info.title}Client'
	client_struct := jsonrpc.generate_client_struct(client_struct_name)

	mut code := []CodeItem{}
	code << client_struct
	code << jsonrpc.generate_ws_factory_code(client_struct_name)!
	methods := jsonrpc.generate_client_methods(client_struct, o.methods.map(it.to_code()!))!
	imports := [codemodel.parse_import('freeflowuniverse.crystallib.rpc.jsonrpc'),
		codemodel.parse_import('freeflowuniverse.crystallib.rpc.rpcwebsocket'),
		codemodel.parse_import('log')]
	code << methods.map(CodeItem(it))
	mut file := CodeFile{
		name:    'client'
		mod:     name
		imports: imports
		items:   code
	}
	for key, object in object_map {
		file.add_import(mod: object.mod, types: [object.name])!
	}
	return file
}

pub fn (method Method) to_code() !Function {
	mut params := []codemodel.Param{}
	for param in method.params {
		if param is ContentDescriptor {
			params << param.to_code()!
		}
	}
	return Function{
		name:   texttools.name_fix_pascal_to_snake(method.name)
		params: params
		result: method.result.to_result()!
	}
}

pub fn (cd ContentDescriptor) to_code() !codemodel.Param {
	return codemodel.Param{
		name: cd.name
		typ:  cd.schema.to_code()!
	}
}

pub fn (cd ContentDescriptorRef) to_result() !codemodel.Result {
	if cd is ContentDescriptor {
		return codemodel.Result{
			name: cd.name
			typ:  cd.schema.to_code()!
		}
	}
	return codemodel.Result{}
}

// generate_structs generates struct codes for schemas defined in an openrpc document
pub fn (o OpenRPC) generate_client_test_file(methods_map map[string]Function, object_map map[string]Struct) !CodeFile {
	name := texttools.name_fix(o.info.title)
	// client_struct_name := '${o.info.title}Client'
	// client_struct := jsonrpc.generate_client_struct(client_struct_name)

	// code << client_struct
	// code << jsonrpc.(client_struct_name)
	// methods := jsonrpc.generate_client_methods(client_struct, o.methods.map(Function{name: it.name}))!

	mut fn_test_factory := parse_function('fn test_new_ws_client() !')!
	fn_test_factory.body = "mut client := new_ws_client(address:'ws://127.0.0.1:\${port}')!"

	mut code := []CodeItem{}
	code << CustomCode{'const port = 3100'}
	code << fn_test_factory
	for key, method in methods_map {
		mut func := parse_function('fn test_${method.name}() !')!
		func_call := method.generate_call(receiver: 'client')!
		func.body = "mut client := new_ws_client(address:'ws://127.0.0.1:\${port}')!\n${func_call}"
		code << func
	}
	mut file := CodeFile{
		name:    'client_test'
		mod:     name
		imports: [
			codemodel.parse_import('freeflowuniverse.crystallib.rpc.jsonrpc'),
			codemodel.parse_import('freeflowuniverse.crystallib.rpc.rpcwebsocket'),
			codemodel.parse_import('log'),
		]
		items:   code
	}

	for key, object in object_map {
		file.add_import(mod: object.mod, types: [object.name])!
	}
	return file
}

// //
// pub fn (s Schema) to_struct() codemodel.Struct {
// 	mut attributes := []Attribute{}
// 	if c.depracated {
// 		attributes << Attribute {name: 'deprecated'}
// 	}
// 	if !c.required {
// 		attributes << Attribute {name: 'params'}
// 	}

// 	return codemodel.Struct {
// 		name: name
// 		description: summary
// 		required: required
// 		schema: Schema {

// 		}
// 		attrs: attributes
// 	}
// }
