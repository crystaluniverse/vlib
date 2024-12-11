module rpcprocessor

import freeflowuniverse.crystallib.clients.redisclient // Assuming this is the path to the Redis client
import freeflowuniverse.crystallib.data.jsonrpc
import time

pub struct RPCProcessorHandler {
	Handler
mut:
	redis_client redisclient.Redis
	queue        redisclient.RedisQueue
}

pub fn new_handler() !RPCProcessorHandler {
	mut redis_client := redisclient.core_get() or {
		return error('Failed to create Redis client: ${err}')
	}
	return RPCProcessorHandler{
		name: 'rpcprocessor_handler'
		methods: ['get_handler']
		// redis_client: redis_client
		queue: redis_client.queue_get('rpcprocessor_handler')
	}
}

// this rpc_handler listens to the echo method's redis queue
// and handles echo rpc
pub fn (mut h RPCProcessorHandler) run() ! {
	mut redis_client := redisclient.core_get() or {
		return error('Failed to create Redis client: ${err}')
	}
	for {
		rpc_id := h.queue.get(1000) or { '' }
		if rpc_id == '' {
			continue
		}

		request_json := redis_client.hget('rpcs.db', rpc_id)!
		request := jsonrpc.jsonrpcrequest_decode[string](request_json) or { panic(err) }
		response := jsonrpc.new_jsonrpcresponse[string](request.id, request.params)

		redis_client.hset('rpcs.db', '${request.id}_response', response.to_json())!
		mut q_response := redis_client.queue_get(request.id)
		q_response.add(response.to_json())!
		time.sleep(1000 * time.millisecond)
	}
}
