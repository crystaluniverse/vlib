module jsonrpc

import json
import x.json2
import rand

const jsonrpc_version = '2.0'

pub struct JsonRpcRequest[T] {
pub mut:
	jsonrpc string @[required]
	method  string @[required]
	params  T      @[required]
	id      string @[required]
}

pub fn (j &JsonRpcRequest[T]) to_json() string {
	return json.encode(j)
}

pub struct JsonRpcResponse[D] {
pub mut:
	jsonrpc string @[required]
	result  D
	id      string @[required]
}

pub fn (j &JsonRpcResponse[D]) to_json() string {
	return json.encode(j)
}

pub struct JsonRpcError {
pub mut:
	jsonrpc string            @[required]
	error   InnerJsonRpcError @[required]
	id      string            @[required]
}

pub struct InnerJsonRpcError {
pub mut:
	code    int    @[required]
	message string @[required]
	data    string
}

pub fn (j &JsonRpcError) to_json() string {
	return json.encode(j)
}

pub fn new_jsonrpcrequest[T](method string, params T) JsonRpcRequest[T] {
	return JsonRpcRequest[T]{
		jsonrpc: jsonrpc.jsonrpc_version
		method: method
		params: params
		id: rand.uuid_v4()
	}
}

pub fn new_jsonrpcresponse[T](id string, result T) JsonRpcResponse[T] {
	return JsonRpcResponse[T]{
		jsonrpc: jsonrpc.jsonrpc_version
		result: result
		id: id
	}
}

pub fn new_response[T](id string, result T) JsonRpcResponse[T] {
	return JsonRpcResponse[T]{
		jsonrpc: jsonrpc.jsonrpc_version
		result: result
		id: id
	}
}

pub fn new_jsonrpcerror(id string, error InnerJsonRpcError) JsonRpcError {
	return JsonRpcError{
		jsonrpc: jsonrpc.jsonrpc_version
		error: error
		id: id
	}
}

pub fn jsonrpcrequest_decode[T](data string) !JsonRpcRequest[T] {
	return json.decode(JsonRpcRequest[T], data)!
}

pub fn decode_request[T](data string) !JsonRpcRequest[T] {
	return json.decode(JsonRpcRequest[T], data)!
}

pub struct JsonRpcRequestAny {
pub mut:
	jsonrpc string @[required]
	method  string @[required]
	id      string @[required]
}

pub fn jsonrpcrequest_decode_method(data string) !string {
	decoded := json.decode(JsonRpcRequestAny, data)!
	return decoded.method
}

pub fn decode_request_method(data string) !string {
	decoded := json.decode(JsonRpcRequestAny, data)!
	return decoded.method
}

pub fn jsonrpcrequest_decode_any(data string) !JsonRpcRequestAny {
	decoded := json.decode(JsonRpcRequestAny, data)!
	return decoded
}

pub fn request_decode_any(data string) !JsonRpcRequestAny {
	decoded := json.decode(JsonRpcRequestAny, data)!
	return decoded
}

// returns json encoded params field of request
pub fn request_params(data string) !string {
	data_any := json2.raw_decode(data)!
	data_map := data_any.as_map()
	params := data_map['params'].str()
	return params
}

pub fn decode_request_id(data string) !string {
	decoded := json.decode(JsonRpcRequestAny, data) or { return error('oops ${err}') }
	return decoded.id
}

pub fn jsonrpcresponse_decode[D](data string) !JsonRpcResponse[D] {
	return json.decode(JsonRpcResponse[D], data)!
}

type Response[D] = JsonRpcError | JsonRpcResponse[D]

pub fn decode_response[D](data string) !Response[D] {
	raw := json2.raw_decode(data)!
	if 'error' in raw.as_map() {
		return json.decode(JsonRpcError, data)!
	}
	return json.decode(JsonRpcResponse[D], data)!
}

// pub fn decode_response[D](data string) !JsonRpcResponse[D] {
// 	raw := json2.raw_decode(data)!
// 	if 'error' in raw.as_map() {
// 		return json.decode(JsonRpcError, data)!
// 	}
// 	return json.decode(JsonRpcResponse[D], data)!
// }

pub fn jsonrpcerror_decode(data string) !JsonRpcError {
	return json.decode(JsonRpcError, data)!
}
