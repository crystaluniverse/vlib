#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.core.generator.generic
import freeflowuniverse.crystallib.clients.mailclient

// generic.generate(path:"/Users/despiegk/code/github/freeflowuniverse/crystallib/crystallib/clients/mailtest")!

// TO TEST:

mut client := mailclient.get()!

println(client)

client.send(
	subject: 'this is a test'
	to:      'kristof@incubaid.com'
	body:    '
    this is my email content
    '
)!
