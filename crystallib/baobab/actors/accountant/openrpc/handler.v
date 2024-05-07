module accountant

@[heap]
struct AccountantHandler {
	state Accountant
}

// handle handles an incoming JSON-RPC encoded message and returns an encoded response
pub fn (mut handler AccountantHandler) handle(msg string) string {
	method := jsonrpc.jsonrpcrequest_decode_method(msg)!
	match method {
		'create_budget' {
			return jsonrpc.call[Budget, int](msg, handler.state.create_budget)!
		}
		'read_budget' {
			return jsonrpc.call[string, Budget](msg, handler.state.read_budget)!
		}
		'update_budget' {
			jsonrpc.notify[Budget](msg, handler.state.update_budget)!
		}
		'delete_budget' {
			jsonrpc.notify[int](msg, handler.state.delete_budget)!
		}
		'list_budget' {
			return jsonrpc.invoke[[]Budget](msg, handler.state.list_budget)!
		}
		else {
			return error('method ${method} not handled')
		}
	}
	return error('this should never happen')
}
