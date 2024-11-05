module webdav

import vweb
import os
import freeflowuniverse.crystallib.core.pathlib

@['/:path...'; get]
fn (mut app App) get_file(path string) vweb.Result {
	mut file_path := pathlib.get_file(path: app.root_dir.path + path) or { return app.not_found() }
	if !file_path.exists() {
		return app.not_found()
	}

	file_stat := os.stat(file_path.path) or { return app.server_error(500) }
	file_size := file_stat.size

	app.set_status(200, 'Ok')
	app.add_header('Content-Length', '${file_size}')

	return app.file(file_path.path)
}

@['/path...'; delete]
fn (mut app App) delete(path string) vweb.Result {
	entry_path := app.root_dir.path + path
	if !os.exists(entry_path) {
		return app.not_found()
	}

	mut p := pathlib.get(entry_path)
	if p.is_dir() {
		println('deleting directory: ${p.path}')
		os.rmdir_all(p.path) or { return app.server_error(500) }
	}

	if p.is_file() {
		println('deleting file: ${p.path}')
		os.rm(p.path) or { return app.server_error(500) }
	}

	println('entry: ${p.path} is deleted')
	app.set_status(204, 'No Content')

	return app.text('entry ${p.path} is deleted')
}
