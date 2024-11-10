module webdav

import vweb
import freeflowuniverse.crystallib.core.pathlib

@[heap]
struct App {
	vweb.Context
	user_db  map[string]string
	root_dir pathlib.Path      @[vweb_global]
pub mut:
	middlewares map[string][]vweb.Middleware
}

fn new_app(root string) !&App {
	root_dir := pathlib.get_dir(path: root, create: true)!
	mut app := &App{
		user_db: {
			'mario': 'hashed_password'
		}
		root_dir: root_dir
	}

	app.middlewares['/'] << logging_middleware
	app.middlewares['/'] << app.auth_middleware

	return app
}

pub fn (mut app App) not_found() vweb.Result {
	app.set_status(404, 'Not Found')
	return app.html('<h1>Page not found</h1>')
}
