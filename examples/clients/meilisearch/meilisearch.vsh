#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.clients.meilisearch


factory := new_factory(host:'http://localhost:7700', api_key:'avrSXQvFdYMbX6MxgWsEmiZYJ3hIGYluUE2blCZzk1U')
mut client := factory.get()!