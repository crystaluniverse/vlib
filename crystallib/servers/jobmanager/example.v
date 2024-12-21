module main

import servers.rpcsocket

fn main() {
	// Create a new RPC server on port 8080
	mut server := rpcsocket.new_server(8080)!
	
	// Start the server (this will block)
	server.start()!
}
