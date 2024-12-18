module main

import log
import json
import freeflowuniverse.crystallib.data.jsonrpc { JsonRpcHandler, jsonrpcrequest_decode }
import freeflowuniverse.crystallib.data.rpcwebsocket
import data.jsonrpc.testdata.testmodule { Config, testfunction0, testfunction1 }

struct CustomJsonRpcHandler {
	JsonRpcHandler
}

fn testfunction0_handler(data string) !string {
	request := jsonrpcrequest_decode[string](data)!
	result := testfunction0(request.params)
	response := jsonrpc.JsonRpcResponse[string]{
		jsonrpc: '2.0.0'
		id:      request.id
		result:  result
	}
	return response.to_json()
}

fn testfunction1_handler(data string) !string {
	request := jsonrpcrequest_decode[Config](data)!
	result := testfunction1(request.params)
	response := jsonrpc.JsonRpcResponse[[]string]{
		jsonrpc: '2.0.0'
		id:      request.id
		result:  result
	}
	return response.to_json()
}

// run_server creates and runs a jsonrpc ws server
// handles rpc requests to reverse_echo function
pub fn run_server() ! {
	mut logger := log.Logger(&log.Log{
		level: .debug
	})

	mut handler := CustomJsonRpcHandler{
		JsonRpcHandler: jsonrpc.new_handler(&logger)!
	}

	handler.state = &state
	// register rpc methods
	handler.register(testfunction0, testfunction0_handle)!
	handler.register(testfunction1, testfunction1_handle)!

	// create & run rpc ws server
	mut jsonrpc_ws_server := rpcwebsocket.new_rpcwsserver(8080, handler, &logger)!
	jsonrpc_ws_server.run()!
}
