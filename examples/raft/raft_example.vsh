#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import raft
import redis
import rand
import time

fn run_node(id string) {
	redis_client := redis.connect('localhost:6379') or { panic(err) }
	mut node := new_raft_node(id, redis_client)
	node.run()
}

for i := 0; i < 7; i++ {
	node_id := rand.uuid_v4()
	go run_node(node_id)
}

// Keep the main thread alive
for {
	time.sleep(1 * time.second)
}
