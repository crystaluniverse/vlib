module jsonrpc

import json
import freeflowuniverse.crystallib.ui.console
import x.json2

// performs jsonrpc call on provided method
pub fn call[T, D](msg string, method fn (T) !D) !string {
	id := decode_request_id(msg) or { return error('Cannot decode request.id ${msg}') }
	req := decode_request[T](msg) or { return new_error(id, invalid_params).to_json() }
	result := method(req.params) or {
		return new_error(id, code: err.code(), message: err.msg()).to_json()
	}
	response := JsonRpcResponse[D]{
		jsonrpc: '2.0.0'
		id:      id
		result:  result
	}
	return json.encode(response)
}

// performs jsonrpc call on provided method that doesnt return anything
// returns ok or error, unlike notify which does not return anything
pub fn call_void[T](msg string, method fn (T) !) !string {
	id := decode_request_id(msg) or { return error('Cannot decode request.id ${msg}') }
	req := decode_request[T](msg) or { return new_error(id, invalid_params).to_json() }
	method(req.params) or { return new_error(id, code: err.code(), message: err.msg()).to_json() }
	response := JsonRpcResponse[string]{
		jsonrpc: '2.0.0'
		id:      id
		result:  'ok'
	}
	return json.encode(response)
}

// performs jsonrpc call on provided method without parameters
pub fn invoke[D](msg string, method fn () !D) !string {
	id := decode_request_id(msg) or { return error('Cannot decode request.id ${msg}') }
	result := method() or { return new_error(id, code: err.code(), message: err.msg()).to_json() }
	response := JsonRpcResponse[D]{
		jsonrpc: '2.0.0'
		id:      id
		result:  result
	}
	return json.encode(response)

	// id := decode_request_id(msg) or {
	// 	return error('Cannot decode request.id ${msg}')
	// }
	// result := method() or {
	// 	return InnerJsonRpcError {code: err.code(), message: err.msg()}
	// }
	// // mut response := ''
	// // $if T is $array {
	// // 	response = "JsonRpcResponse[T]{jsonrpc: '2.0.0', id: id, result:result}"
	// // } $else {
	// // 	resp := JsonRpcResponse[T]{jsonrpc: '2.0.0', id: id, result:result}
	// // 	return json.encode(resp)
	// // }
	// response := JsonRpcResponse[T]{jsonrpc: '2.0.0', id: id, result:result}
	// return json.encode(response)
}

pub fn notify[T](params_json string, method fn (T) !) {
	params := json2.decode[T](params_json) or { return }
	method(params) or { console.print_debug(err) }
}

// TODO
fn decode_params[T](params_json string) !T {
	$if T is string {
		return params_json
	} $else {
		return json.decode(T, params_json) or { return invalid_params }
	}
}
