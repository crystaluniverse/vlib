module main

import freeflowuniverse.crystallib.data.rpcwebsocket
import freeflowuniverse.crystallib.data.jsonrpc
import freeflowuniverse.crystallib.ui.console
import log
import net.websocket
import json

pub fn main() {
	console.print_debug('Running websocket example\n')
	websocket_example()!
}

struct PetstoreJsonRpcWsHandler {
mut:
	handler PetstoreJsonRpcHandler
}

fn (mut h PetstoreJsonRpcWsHandler) handle(client &websocket.Client, msg string) string {
	return h.handler.handle(msg) or {
		// client.return error
		panic(err)
	}
}

pub fn websocket_example() ! {
	mut logger := log.Logger(&log.Log{
		level: .debug
	})

	mut ws_handler := PetstoreJsonRpcWsHandler{}
	mut ws_server := rpcwebsocket.new_rpcwsserver(8080, ws_handler.handle, &logger)!

	spawn ws_server.run()

	mut ws_client := new_petstore_json_rpc_ws_client(
		address: 'ws://127.0.0.1:8080'
		logger:  logger
	)!
	pets := ws_client.get_pet('test_pet')!
	// handler.run()!
}
