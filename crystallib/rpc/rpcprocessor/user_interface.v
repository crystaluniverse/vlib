module rpcprocessor

import freeflowuniverse.crystallib.clients.redisclient // Assuming this is the path to the Redis client
import freeflowuniverse.crystallib.data.rpcwebsocket // Assuming this is the path to the Redis client
import freeflowuniverse.crystallib.data.jsonrpc
import net.websocket
import time
import vweb
import log
import eventbus
import rand

struct RPCProcessorUI {
	vweb.Context
pub mut:
	processor RPCProcessor @[vweb_global]
	client    Client       @[vweb_global]
}

pub fn (mut p RPCProcessor) run_ui() ! {
	client := new_client() or { panic(err) }
	ui := RPCProcessorUI{
		processor: p
		client:    client
	}
	vweb.run(ui, 8080)
}

pub fn (mut ui RPCProcessorUI) index() vweb.Result {
	handlers := ui.client.get_handlers() or { panic(err) }
	latest_activity := ui.client.get_latest_activity() or { panic(err) }
	return ui.html($tmpl('./templates/index.html'))
}

// pub fn (mut ui RPCProcessorUI) handler() vweb.Result {
//     return ui.html($tmpl('./templates/handler.html'))
// }

@['/handler/:name'; get]
pub fn (mut ui RPCProcessorUI) handler_page(name string) vweb.Result {
	handler := ui.client.get_handler(name) or { panic(err) }
	return ui.html($tmpl('./templates/handler.html'))
}

@['/rpcs/:id'; get]
pub fn (mut ui RPCProcessorUI) rpc(id string) vweb.Result {
	rpc := ui.client.get_rpc(id) or { panic(err) }
	return ui.html($tmpl('./templates/rpc.html'))
}

struct Method {
pub:
	name string
}

@['/handler/:name/methods'; get]
pub fn (mut ui RPCProcessorUI) handler_methods(name string) vweb.Result {
	methods := []Method{}
	handler := ui.client.get_handler(name) or { panic(err) }
	return ui.html($tmpl('./templates/handler_methods.html'))
}
