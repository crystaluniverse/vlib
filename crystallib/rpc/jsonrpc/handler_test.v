module jsonrpc

import log
import freeflowuniverse.crystallib.rpc.rpcwebsocket { new_rpcwsserver }
import time
import net.websocket

fn procedure(text string) !string {
	return 'response to ${text}'
}

fn procedure_handler(data string) !string {
	request := jsonrpcrequest_decode[string](data)!
	result := procedure(request.params)!
	response := JsonRpcResponse[string]{
		jsonrpc: jsonrpc_version
		id:      request.id
		result:  result
	}
	return response.to_json()
}

fn test_new() {
	mut logger := log.Logger(&log.Log{
		level: .debug
	})
	mut handler := new_handler(&logger)!
}

fn test_register() {
	mut logger := log.Logger(&log.Log{
		level: .debug
	})
	mut handler := new_handler(&logger)!
	handler.register('test', procedure_handler)!
}

fn test_handle() {
	mut logger := log.Logger(&log.Log{
		level: .debug
	})
	mut handler := new_handler(&logger)!
	handler.register('test', procedure_handler)!
	request := new_jsonrpcrequest[string]('test', 'payload')
	result := handler.handle(request.to_json())!
	response := jsonrpcresponse_decode[string](result)!
	assert response.result == 'response to payload'
}

struct Counter {
mut:
	count int = 0
}

struct CounterJsonRpcHandler {
	JsonRpcHandler
}

pub fn (mut counter Counter) increment(steps int) !int {
	counter.count += steps
	return counter.count
}

pub fn (mut handler CounterJsonRpcHandler) increment_handler(data string) !string {
	request := jsonrpcrequest_decode[int](data)!
	mut counter := unsafe { &Counter(handler.state) }
	result := counter.increment(request.params)!
	response := JsonRpcResponse[int]{
		jsonrpc: jsonrpc_version
		id:      request.id
		result:  result
	}
	return response.to_json()
}

fn test_stateful_handle() {
	mut logger := log.Logger(&log.Log{
		level: .debug
	})
	counter := Counter{}
	mut handler := CounterJsonRpcHandler{
		JsonRpcHandler: new_handler(&logger)!
	}
	handler.state = &counter
	handler.register('increment', handler.increment_handler)!
	// counter_handler.JsonRpcHandler = handler

	request0 := new_jsonrpcrequest[int]('increment', 2)
	result0 := handler.handle(request0.to_json())!
	response0 := jsonrpcresponse_decode[int](result0)!
	assert response0.result == 2

	request1 := new_jsonrpcrequest[int]('increment', 3)
	result1 := handler.handle(request1.to_json())!
	response1 := jsonrpcresponse_decode[int](result1)!
	assert response1.result == 5
}

fn test_jsonrpc_ws_server() {
	mut logger := log.Logger(&log.Log{
		level: .debug
	})
	mut handler := new_handler(&logger)!
	handler.register('test', procedure_handler)!

	mut jsonrpc_ws_server := new_rpcwsserver(8080, handler.handler, &logger)!
	spawn jsonrpc_ws_server.run()
	time.sleep(10000000)

	mut ws := websocket.new_client('ws://localhost:8080')!
	ws.on_open(fn (mut ws websocket.Client) ! {})
	ws.on_error(fn (mut ws websocket.Client, err string) ! {})
	ws.on_close(fn (mut ws websocket.Client, code int, reason string) ! {})
	ws.on_message(fn (mut ws websocket.Client, msg &websocket.Message) ! {
		if msg.payload.len > 0 {
			message := msg.payload.bytestr()
			response := jsonrpcresponse_decode[string](message)!
			assert response.result == 'response to payload'
		}
	})

	ws.connect()!
	spawn ws.listen()
	defer {
		unsafe {
			ws.free()
		}
	}
	time.sleep(10000000)

	request := new_jsonrpcrequest[string]('test', 'payload')
	ws.write_string(request.to_json())!
	time.sleep(10000000)
	ws.close(1000, 'normal')!
}

// fn test_stateful_jsonrpc_ws_server() {
// 	mut logger := log.Logger(&log.Log{
// 		level: .debug
// 	})
// 	mut handler := new_handler(&logger)!
// 	handler.register('test', procedure_handler)!

// 	mut jsonrpc_ws_server := new_rpcwsserver(8080, handler, &logger)!
// 	spawn jsonrpc_ws_server.run()
// 	time.sleep(10000000)

// 	mut ws := websocket.new_client('ws://localhost:8080')!
// 	ws.on_open(fn (mut ws websocket.Client) ! {})
// 	ws.on_error(fn (mut ws websocket.Client, err string) ! {})
// 	ws.on_close(fn (mut ws websocket.Client, code int, reason string) ! {})
// 	ws.on_message(fn (mut ws websocket.Client, msg &websocket.Message) ! {
// 		if msg.payload.len > 0 {
// 			message := msg.payload.bytestr()
// 			response := jsonrpcresponse_decode[string](message)!
// 			assert response.result == 'response to payload'
// 		}
// 	})

// 	ws.connect()!
// 	spawn ws.listen()
// 	defer {
// 		unsafe {
// 			ws.free()
// 		}
// 	}
// 	time.sleep(10000000)

// 	request := new_jsonrpcrequest[string]('test', 'payload')
// 	ws.write_string(request.to_json())!
// 	time.sleep(10000000)
// 	ws.close(1000, 'normal')!
// }
