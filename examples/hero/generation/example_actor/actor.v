module example_actor

import freeflowuniverse.crystallib.clients.redisclient

@[heap]
struct Actor {
mut:
    rpc redisclient.RedisRpc
}