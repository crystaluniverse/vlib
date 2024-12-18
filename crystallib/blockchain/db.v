module blockchain

import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.data.ourdb
import freeflowuniverse.crystallib.clients.meilisearch

@[heap]
pub struct DADB {
pub mut:
	name        string
	secret      string
	db          ourdb.OurDB
	meilisearch meilisearch.MeilisearchClient
}

@[params]
pub struct NewArgs {
pub mut:
	path   string @[required] // path where all the DB info will be
	secret string @[required]
}

pub fn new(args NewArgs) !DADB {
	mut db := ourdb.new(path: args.path)!
	mut meilisearch := meilisearch.get()!

	return DADB{
		name:        args.name
		db:          db
		secret:      secret
		meilisearch: meilisearch
	}
}
