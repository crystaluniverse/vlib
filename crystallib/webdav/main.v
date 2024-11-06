module main

import vweb

fn main() {
	root_dir := '/tmp/webdav'
	app := new_app(root_dir) or {
		eprintln('failed to create new server: ${err}')
		exit(1)
	}

	vweb.run(app, 8080)
}
