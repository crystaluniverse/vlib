module jsonrpc

import freeflowuniverse.crystallib.core.codemodel { Attribute, CodeFile, CodeItem, Function, Module, Param, Struct, StructField, Type, parse_function }
import freeflowuniverse.crystallib.core.texttools

pub struct GenerateClientConfig {
	name    string
	methods []Function
}

pub fn generate_client(config GenerateClientConfig) Module {
	factory_file := generate_client_factory(config.name) or { panic(err) }
	return Module{
		files: [
			factory_file,
		]
	}
}

// generate_client_factory generates a factory code file with factory functions for the client
pub fn generate_client_factory(name string) !CodeFile {
	mut code := []CodeItem{}
	code << generate_client_struct(name)
	code << generate_ws_factory_code(name)!

	return CodeFile{
		mod:     name
		imports: []
		items:   code
	}
}

pub fn generate_client_struct(name string) Struct {
	return Struct{
		name:   texttools.name_fix_snake_to_pascal(name)
		fields: [
			StructField{
				name:   'transport'
				typ:    Type{
					symbol: 'jsonrpc.IRpcTransportClient'
				}
				is_mut: true
			},
		]
	}
}

pub fn generate_ws_factory_code(name_ string) ![]CodeItem {
	name := texttools.name_fix_snake_to_pascal(name_)
	ws_factory_param := Struct{
		name:   'WsClientConfig'
		is_pub: true
		attrs:  [Attribute{
			name: 'params'
		}]
		fields: [
			StructField{
				name:  'address'
				typ:   Type{
					symbol: 'string'
				}
				attrs: [Attribute{
					name: 'required'
				}]
			},
			StructField{
				name: 'logger'
				typ:  Type{
					symbol: 'log.Logger'
				}
			},
		]
	}

	mut ws_factory_function := parse_function('pub fn new_ws_client(config WsClientConfig) !&${name}')!
	ws_factory_function.body = "mut transport := rpcwebsocket.new_rpcwsclient(config.address, config.logger) or {
		return error('Failed to create RPC Websocket Client\\n\${err}')
	}
	spawn transport.run()
	c := ${name} {
		transport: transport
	}
	return &c"
	return [ws_factory_param, ws_factory_function]
}

pub fn generate_client_methods(client_struct Struct, methods []Function) ![]Function {
	return methods.map(generate_client_method(client_struct, it)!)
}

/*
pub fn (mut client PetstoreJsonRpcClient) get_pet(name string) !Pet {
	request := jsonrpc.new_jsonrpcrequest[string]('get_pet', name)
	response := client.transport.send(request.to_json(), 6000)!
	return json.decode(Pet, response)!
}
*/
pub fn generate_client_method(client_struct Struct, method Function) !Function {
	if method.params.len > 1 {
		return error('json rpc calls with more than 1 param are not supported')
	}

	request_stmt := if method.params.len == 0 {
		"request := jsonrpc.new_jsonrpcrequest[string]('${method.name}', '')"
	} else {
		"request := jsonrpc.new_jsonrpcrequest[${method.params[0].typ.symbol}]('${method.name}', ${method.params[0].name})"
	}

	return_stmt := if method.result.typ.symbol == '' {
		'resp_json := client.transport.send(request.to_json(), 6000)!
	response := jsonrpc.decode_response[string](resp_json)!
	if response is jsonrpc.JsonRpcError {
		return response.error
	}'
	} else {
		'resp_json := client.transport.send(request.to_json(), 6000)!
		response := jsonrpc.decode_response[${method.result.typ.symbol}](resp_json)!
		if response is jsonrpc.JsonRpcError {
			return response.error
		}
		return (response as jsonrpc.JsonRpcResponse[${method.result.typ.symbol}]).result'
	}

	mut func := Function{
		...method
		receiver: Param{
			name:    'client'
			typ:     Type{
				symbol: client_struct.name
			}
			mutable: true
		}
		body:     '${request_stmt}\n${return_stmt}'
	}
	func.result.result = true
	return func
}
