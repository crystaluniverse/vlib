module main

import servers.jobmanager

fn main() {
	// Create a new RPC server on port 8080
	mut server := jobmanager.new_server(8080)!

	// Start the server (this will block)
	server.start()!
}
