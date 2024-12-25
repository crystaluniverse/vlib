module actor

import json
import freeflowuniverse.crystallib.clients.redisclient
import freeflowuniverse.crystallib.hero.baobab.action { ProcedureCall, ProcedureResponse }

// Processor struct for managing procedure calls
pub struct Client {
pub mut:
	rpc redisclient.RedisRpc // Redis RPC mechanism
}

// Parameters for processing a procedure call
@[params]
pub struct Params {
pub:
	timeout int // Timeout in seconds
}

pub struct ClientConfig {
pub:
	redis_url   string // url to redis server running
	redis_queue string // name of redis queue
}

pub fn new_client(config ClientConfig) !Client {
	mut redis := redisclient.new(config.redis_url)!
	mut rpc_q := redis.rpc_get(config.redis_queue)

	return Client{
		rpc: rpc_q
	}
}

// Process the procedure call
pub fn (mut p Client) monologue(call ProcedureCall, params Params) ! {
	// Use RedisRpc's `call` to send the call and wait for the response
	response_data := p.rpc.call(redisclient.RPCArgs{
		cmd:     call.method
		data:    call.params
		timeout: u64(params.timeout * 1000) // Convert seconds to milliseconds
		wait:    true
	})!
        // TODO: check error type
}

// Process the procedure call
pub fn (mut p Client) call_to_action (action Procedure, params Params) !ProcedureResponse {
	// Use RedisRpc's `call` to send the call and wait for the response
	response_data := p.rpc.call(redisclient.RPCArgs{
		cmd:     call.method
		data:    call.params
		timeout: u64(params.timeout * 1000) // Convert seconds to milliseconds
		wait:    true
	}) or {
		// TODO: check error type
		return ProcedureResponse{
			error: err.msg()
		}
		// return ProcedureError{
		//     reason: .timeout
		// }
	}

	println('resp data ${response_data}')

	return ProcedureResponse{
		result: response_data
	}
}
