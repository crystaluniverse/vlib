module meilisearch

import freeflowuniverse.crystallib.clients.httpconnection

// Factory creates new instances of MeiliClient
pub struct Factory {
mut:
	config ClientConfig
}

// new_factory creates a new Factory instance with the given configuration
pub fn new_factory(config ClientConfig) Factory {
	return Factory{
		config: config
	}
}

// get returns a new configured MeiliClient instance
pub fn (f Factory) get() !MeiliClient {
	mut http_conn := httpconnection.new(
		name:  'meilisearch'
		url:   f.config.host
		retry: f.config.max_retry
	)!

	// Add authentication header if API key is provided
	if f.config.api_key.len > 0 {
		http_conn.default_header.add(.authorization, 'Bearer ${f.config.api_key}')
	}

	return MeiliClient{
		config: f.config
		http:   http_conn
	}
}
