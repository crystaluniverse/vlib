module meilisearch

import freeflowuniverse.crystallib.data.paramsparser
import freeflowuniverse.crystallib.clients.httpconnection
import os

pub const version = '1.0.0'
const singleton = false
const default = true

// TODO: THIS IS EXAMPLE CODE AND NEEDS TO BE CHANGED IN LINE TO STRUCT BELOW, IS STRUCTURED AS HEROSCRIPT
pub fn heroscript_default() !string {
	heroscript := "
    !!meilisearch.configure 
        name:'default'
		host:'http://localhost:7700'
		api_key:'be61fdce-c5d4-44bc-886b-3a484ff6c531'
        "
	return heroscript
}

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED

pub struct MeilisearchClient {
pub mut:
	name    string = 'default'
	api_key string @[secret]
	host    string
}

fn cfg_play(p paramsparser.Params) ! {
	// THIS IS EXAMPLE CODE AND NEEDS TO BE CHANGED IN LINE WITH struct above
	mut mycfg := MeilisearchClient{
		name:    p.get_default('name', 'default')!
		host:    p.get('host')!
		api_key: p.get('api_key')!
	}
	set(mycfg)!
}

fn obj_init(obj_ MeilisearchClient) !MeilisearchClient {
	// never call get here, only thing we can do here is work on object itself
	mut obj := obj_
	// set the http client
	return obj
}

fn (mut self MeilisearchClient) httpclient() !&httpconnection.HTTPConnection {
	mut http_conn := httpconnection.new(
		name: 'meilisearch'
		url:  self.host
	)!

	// Add authentication header if API key is provided
	if self.api_key.len > 0 {
		http_conn.default_header.add(.authorization, 'Bearer ${self.api_key}')
	}
	return http_conn
}
