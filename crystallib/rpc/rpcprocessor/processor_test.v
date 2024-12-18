module rpcprocessor

import freeflowuniverse.crystallib.clients.redisclient // Assuming this is the path to the Redis client
import freeflowuniverse.crystallib.data.rpcwebsocket // Assuming this is the path to the Redis client
import net.websocket
import freeflowuniverse.crystallib.data.jsonrpc
import time
import log

const redis_addr = 'http://127.0.0.1'
const redis_port = 6380
const ws_port = 8080

fn test_new_processor() ! {
	processor := new(
		redis_url: redisclient.RedisURL{
			address: redis_addr
			port:    redis_port
		}
	)!

	mut logger := log.Logger(&log.Log{
		level: .debug
	})

	mut ws_server := rpcwebsocket.new_rpcwsserver(ws_port, processor.handler, logger)!

	spawn ws_server.run()
	time.sleep(100 * time.millisecond)
	messages := ['11', '12', '32']
	spawn run_rpc_handler()
	time.sleep(300 * time.millisecond)
	// run_client('http://127.0.0.1:${ws_port}', logger, messages)!
	time.sleep(100 * time.millisecond)
}

// this rpc_handler listens to the echo method's redis queue
// and handles echo rpc
fn run_rpc_handler() ! {
	mut redis_client := redisclient.new(
		address: redis_addr
		port:    redis_port
	) or { return error('Failed to create Redis client: ${err}') }
	for {
		results := redis_client.brpop(['echo'], 0) or {
			panic('Failed to fetch RPC result from Redis queue: ${err}')
		}
		if results.len == 1 {
			request := jsonrpc.jsonrpcrequest_decode[string](results[0])!
			response := jsonrpc.new_jsonrpcresponse[string](request.id, request.params)
			redis_client.lpush(request.id, response.to_json())!
		}
		time.sleep(100 * time.millisecond)
	}
}

fn run_client(address string, logger &log.Logger, messages []string) ![]string {
	mut myclient := rpcwebsocket.new_rpcwsclient(address, logger)!
	t_client := spawn myclient.run()
	mut responses := []string{}
	for message in messages {
		responses << myclient.send_json_rpc[string, string]('echo', message, 5000)!
	}
	myclient.client.close(0, "I'm done here")!
	t_client.wait()!
	return responses
}
