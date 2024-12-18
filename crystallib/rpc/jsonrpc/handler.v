module jsonrpc

import log
import net.websocket

// JSON-RPC WebSoocket Server

@[heap]
pub struct JsonRpcHandler {
pub mut:
	// rpcwebsocket.RpcWsServer // server for ws communication
	// map of method names to procedure handlers
	procedures map[string]ProcedureHandler
	state      voidptr
}

// ProcedureHandler handles executing procedure calls
// decodes payload, execute procedure function, return encoded result
type ProcedureHandler = fn (payload string) !string

pub fn new_handler() !&JsonRpcHandler {
	return &JsonRpcHandler{}
}

// registers procedure handlers by method name
pub fn (mut server JsonRpcHandler) register(name string, procedure ProcedureHandler) ! {
	server.procedures[name] = procedure
}

pub fn (mut handler JsonRpcHandler) handler(client &websocket.Client, message string) string {
	return handler.handle(message) or { panic(err) }
}

pub fn (mut handler JsonRpcHandler) handle(message string) !string {
	method := jsonrpcrequest_decode_method(message)!
	println('handler-> handling remote procedure call to method: ${method}')
	procedure_func := handler.procedures[method]
	response := procedure_func(message) or { panic(err) }
	return response
}
