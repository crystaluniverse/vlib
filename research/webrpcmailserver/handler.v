module mail

import log
import json
import freeflowuniverse.crystallib.data.jsonrpc { jsonrpcrequest_decode }
import freeflowuniverse.crystallib.core.openrpc { OpenRpcHandler }
import freeflowuniverse.crystallib.rpchandler

struct MailOpenRpcHandler {
	OpenRpcHandler
}

fn (mut handler MailOpenRpcHandler) close_handle(data string) !string {
	mut receiver := &Mail(handler.state)

	request := json.decode(jsonrpc.JsonRpcRequestAny, data)!
	receiver.close()!

	response := jsonrpc.JsonRpcResponse[string]{
		jsonrpc: '2.0.0'
		id:      request.id
		result:  ''
	}
	return response.to_json()
}

fn (mut handler MailOpenRpcHandler) select__handle(data string) !string {
	mut receiver := &Mail(handler.state)

	request := jsonrpcrequest_decode[SelectParams](data)!
	receiver.select_(request.params)!

	response := jsonrpc.JsonRpcResponse[string]{
		jsonrpc: '2.0.0'
		id:      request.id
		result:  ''
	}
	return response.to_json()
}

fn (mut handler MailOpenRpcHandler) create_handle(data string) !string {
	mut receiver := &Mail(handler.state)

	request := jsonrpcrequest_decode[CreateParams](data)!
	receiver.create(request.params)!

	response := jsonrpc.JsonRpcResponse[string]{
		jsonrpc: '2.0.0'
		id:      request.id
		result:  ''
	}
	return response.to_json()
}

fn (mut handler MailOpenRpcHandler) delete_handle(data string) !string {
	mut receiver := &Mail(handler.state)

	request := jsonrpcrequest_decode[string](data)!
	receiver.delete(request.params)!

	response := jsonrpc.JsonRpcResponse[string]{
		jsonrpc: '2.0.0'
		id:      request.id
		result:  ''
	}
	return response.to_json()
}

fn (mut handler MailOpenRpcHandler) rename_handle(data string) !string {
	mut receiver := &Mail(handler.state)

	request := jsonrpcrequest_decode[RenameParams](data)!
	receiver.rename(request.params)!

	response := jsonrpc.JsonRpcResponse[string]{
		jsonrpc: '2.0.0'
		id:      request.id
		result:  ''
	}
	return response.to_json()
}

fn (mut handler MailOpenRpcHandler) subscribe_handle(data string) !string {
	mut receiver := &Mail(handler.state)

	request := jsonrpcrequest_decode[string](data)!
	receiver.subscribe(request.params)!

	response := jsonrpc.JsonRpcResponse[string]{
		jsonrpc: '2.0.0'
		id:      request.id
		result:  ''
	}
	return response.to_json()
}

fn (mut handler MailOpenRpcHandler) unsubscribe_handle(data string) !string {
	mut receiver := &Mail(handler.state)

	request := jsonrpcrequest_decode[string](data)!
	receiver.unsubscribe(request.params)!

	response := jsonrpc.JsonRpcResponse[string]{
		jsonrpc: '2.0.0'
		id:      request.id
		result:  ''
	}
	return response.to_json()
}

fn (mut handler MailOpenRpcHandler) list_handle(data string) !string {
	mut receiver := &Mail(handler.state)

	request := jsonrpcrequest_decode[ListOptions](data)!
	receiver.list(request.params)!

	response := jsonrpc.JsonRpcResponse[string]{
		jsonrpc: '2.0.0'
		id:      request.id
		result:  ''
	}
	return response.to_json()
}

fn (mut handler MailOpenRpcHandler) status_handle(data string) !string {
	mut receiver := &Mail(handler.state)

	request := jsonrpcrequest_decode[StatusParams](data)!
	receiver.status(request.params)!

	response := jsonrpc.JsonRpcResponse[string]{
		jsonrpc: '2.0.0'
		id:      request.id
		result:  ''
	}
	return response.to_json()
}

fn (mut handler MailOpenRpcHandler) append_handle(data string) !string {
	mut receiver := &Mail(handler.state)

	request := jsonrpcrequest_decode[AppendParams](data)!
	receiver.append(request.params)!

	response := jsonrpc.JsonRpcResponse[string]{
		jsonrpc: '2.0.0'
		id:      request.id
		result:  ''
	}
	return response.to_json()
}

fn (mut handler MailOpenRpcHandler) poll_handle(data string) !string {
	mut receiver := &Mail(handler.state)

	request := jsonrpcrequest_decode[bool](data)!
	receiver.poll(request.params)!

	response := jsonrpc.JsonRpcResponse[string]{
		jsonrpc: '2.0.0'
		id:      request.id
		result:  ''
	}
	return response.to_json()
}

fn (mut handler MailOpenRpcHandler) idle_handle(data string) !string {
	mut receiver := &Mail(handler.state)

	request := json.decode(jsonrpc.JsonRpcRequestAny, data)!
	receiver.idle()!

	response := jsonrpc.JsonRpcResponse[string]{
		jsonrpc: '2.0.0'
		id:      request.id
		result:  ''
	}
	return response.to_json()
}

pub struct HandlerParams {
	logger       &log.Logger
	state        voidptr
	openrpc_path string
}

// run_server creates and runs a jsonrpc ws server
// handles rpc requests to reverse_echo function
pub fn new_handler(params HandlerParams) !&MailOpenRpcHandler {
	mut handler := MailOpenRpcHandler{
		OpenRpcHandler: crystallib.core.openrpc.new_handler(params.logger, params.openrpc_path)!
	}

	handler.state = params.state
	// register rpc methods
	handler.register('close', handler.close_handle)!
	handler.register('select_', handler.select__handle)!
	handler.register('create', handler.create_handle)!
	handler.register('delete', handler.delete_handle)!
	handler.register('rename', handler.rename_handle)!
	handler.register('subscribe', handler.subscribe_handle)!
	handler.register('unsubscribe', handler.unsubscribe_handle)!
	handler.register('list', handler.list_handle)!
	handler.register('status', handler.status_handle)!
	handler.register('append', handler.append_handle)!
	handler.register('poll', handler.poll_handle)!
	handler.register('idle', handler.idle_handle)!

	return &handler
}
