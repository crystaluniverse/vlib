module processor

import freeflowuniverse.crystallib.clients.redisclient

// Processor struct for managing procedure calls
pub struct Processor {
pub mut:
    rpc redisclient.RedisRpc // Redis RPC mechanism
}

// Parameters for processing a procedure call
@[params]
pub struct ProcessParams {
pub:
    timeout int // Timeout in seconds
}

// Process the procedure call
pub fn (mut p Processor) process(call ProcedureCall, params ProcessParams) !ProcedureResponse {
    // Use RedisRpc's `call` to send the call and wait for the response
    response_data := p.rpc.call(redisclient.RPCArgs{
        cmd: call.method
        data: call.params
        timeout: u64(params.timeout * 1000) // Convert seconds to milliseconds
        wait: true
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