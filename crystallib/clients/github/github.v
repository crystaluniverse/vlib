module github

import os
import freeflowuniverse.crystallib.clients.httpconnection

pub struct GithubClient {
mut:
	graphql_connection &httpconnection.HTTPConnection
}

pub fn new() !GithubClient {
	mut conn := httpconnection.new(
		name: 'github-graphql'
		url:  'https://api.github.com/graphql'
	)!

	env := os.environ()
	if 'GITHUB_TOKEN' !in env {
		return error('need to set `GITHUB_TOKEN` environment variable with a valid token')
	}
	key := env['GITHUB_TOKEN']
	conn.default_header.add(.authorization, 'Bearer ${key}')

	return GithubClient{
		graphql_connection: conn
	}
}
