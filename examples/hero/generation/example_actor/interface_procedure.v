module example_actor

import freeflowuniverse.crystallib.clients.redisclient
import time

pub fn run_interface_procedure() {
    mut redis := redisclient.new('localhost:6379') or {panic(err)}
    mut rpc := redis.rpc_get('procedure_queue')

    mut actor := Actor{
        rpc: rpc
    }

    actor.listen() or {panic(err)}
}

// Actor listens to the Redis queue for method invocations
fn (mut actor Actor) listen() ! {
    println('Actor started and listening for tasks...')
    for {
        actor.rpc.process(actor.handle_method)!
        time.sleep(time.millisecond * 100) // Prevent CPU spinning
    }
}