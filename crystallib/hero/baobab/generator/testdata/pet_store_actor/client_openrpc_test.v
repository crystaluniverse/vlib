module pet_store_actor
import freeflowuniverse.crystallib.rpc.jsonrpc 
import freeflowuniverse.crystallib.rpc.rpcwebsocket 
import log 


const port = 3100
pub fn  test_new_ws_client() ! {
	mut client := new_ws_client(address:'ws://127.0.0.1:${port}')!
}