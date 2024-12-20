module actor

import freeflowuniverse.crystallib.clients.redisclient
import time

// import freeflowuniverse.crystallib.baobab.osis

// pub struct Actor {
// pub mut:
// 	osis osis.OSIS
// }

// pub struct ActorConfig {
// 	osis.OSISConfig
// }

// pub fn new(config ActorConfig) !Actor {
// 	return Actor{
// 		osis: osis.new(config.OSISConfig)!
// 	}
// }

pub interface IActor {
	name string
mut:
	handle(string, string) !string
}

pub struct Actor {
pub:
	name string
}

pub fn new(name string) Actor {
	return Actor{name}
}

// Actor listens to the Redis queue for method invocations
pub fn (mut actor IActor) run() ! {
	mut redis := redisclient.new('localhost:6379') or { panic(err) }
	mut rpc := redis.rpc_get(actor.name)

	println('Actor started and listening for tasks...')
	for {
		rpc.process(actor.handle)!
		time.sleep(time.millisecond * 100) // Prevent CPU spinning
	}
}
