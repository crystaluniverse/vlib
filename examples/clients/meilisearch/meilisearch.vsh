#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.clients.meilisearch

struct MeiliDocument {
pub mut:
	id      int
	title   string
	content string
}

factory := new_factory(host:'http://localhost:7700', api_key:'be61fdce-c5d4-44bc-886b-3a484ff6c531')
mut client := factory.get()!

version := client.version()
println('version: ${version}')

