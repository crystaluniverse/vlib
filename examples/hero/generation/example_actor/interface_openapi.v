module example_actor

import freeflowuniverse.crystallib.clients.redisclient
import freeflowuniverse.crystallib.web.openapi {Server, Context, Request, Response}
import freeflowuniverse.crystallib.hero.processor {Processor, Handler, ProcedureResponse, ProcessParams}

fn main() {
    // Initialize the Redis client and RPC mechanism
    mut redis := redisclient.new('localhost:6379')!
    mut rpc := redis.rpc_get('procedure_queue')

    // Initialize the server
    mut server := &Server{
        specification: openapi.json_decode(spec_json)!
        handler: Handler{
            processor: Processor{
                rpc: rpc
            }
        }
    }

    // Start the server
    veb.run[Server, Context](mut server, 8080)
}