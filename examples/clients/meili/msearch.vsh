#!/usr/bin/env -S v -cg -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.clients.meilisearch
import freeflowuniverse.crystallib.installers.db.meilisearchinstaller

struct MeiliDocument {
pub mut:
	id      int
	title   string
	content string
}

heroscript := "

!!meilisearchinstaller.configure name:'test'
	masterkey: '1234'
	port: 7702
	production: 0

!!meilisearchinstaller.destroy

!!meilisearchinstaller.start name:'test'

"

meilisearchinstaller.play(heroscript: heroscript)!

// mut installer:= meilisearch.get()!

// mut client := meilisearch.get()!
// version := client.version()!
// println('version: ${version}')
