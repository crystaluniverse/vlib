module caddy

import freeflowuniverse.crystallib.core.pathlib
import os

const testdata_path = '${os.dir(@FILE)}/testdata'

fn test_add_reverse_proxy() {
	mut file := CaddyFile{}

	file.add_reverse_proxy(
		from: '/api'
		to:   'http://localhost:8080'
	) or {
		assert false, 'Failed to add reverse proxy: ${err}'
		return
	}
}

fn test_add_file_server() {
	mut file := CaddyFile{}

	file.add_file_server(
		domain: 'example.com'
		root:   '${testdata_path}/example'
	) or {
		assert false, 'Failed to add file server: ${err}'
		return
	}
}
