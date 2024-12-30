#!/usr/bin/env -S v -w -n -enable-globals run

import freeflowuniverse.crystallib.hero.baobab.generator
import freeflowuniverse.crystallib.hero.baobab.specification
import freeflowuniverse.crystallib.rpc.openrpc
import os

const example_dir = os.dir(@FILE)
const openrpc_spec_path = os.join_path(example_dir, 'openrpc.json')

// the actor specification obtained from the OpenRPC Specification
openrpc_spec := openrpc.new(path: openrpc_spec_path)!
actor_spec := specification.from_openrpc(openrpc_spec)!

generator.generate_actor_module(
	actor_spec,
	interfaces: [.openrpc]
)!