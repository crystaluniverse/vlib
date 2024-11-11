#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.clients.meilisearch

struct MeiliDocument {
pub mut:
	id      int
	title   string
	content string
}

mut client := meilisearch.get()!
version := client.version()!
println('version: ${version}')

