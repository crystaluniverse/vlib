#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.builder

// name string  @[required]
// address string @[required]
// remote_port int  @[required]

builder.portforward_to_local(
	name:        'holo1'
	address:     '[302:1d81:cef8:3049:fbe1:69ba:bd8c:52ec]'
	remote_port: 45579
)!
builder.portforward_to_local(
	name:        'holo2'
	address:     '[302:1d81:cef8:3049:fbe1:69ba:bd8c:52ec]'
	remote_port: 34639
)!
builder.portforward_to_local(
	name:        'holoui'
	address:     '[302:1d81:cef8:3049:fbe1:69ba:bd8c:52ec]'
	remote_port: 8282
)!
