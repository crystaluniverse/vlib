module pet_store_actor
import freeflowuniverse.crystallib.rpc.jsonrpc 
import freeflowuniverse.crystallib.rpc.rpcwebsocket 
import log 



 struct Client {

mut:
transport jsonrpc.IRpcTransportClient
}


[
    params
]
pub struct WsClientConfig {
address string
logger log.Logger
}

pub fn  new_ws_client(config WsClientConfig) !&Client {
	mut transport := rpcwebsocket.new_rpcwsclient(config.address, config.logger) or {
		return error('Failed to create RPC Websocket Client\n${err}')
	}
	spawn transport.run()
	c := Client {
		transport: transport
	}
	return &c
}