module webdav

import vweb
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.ui.console

@[heap]
struct App {
	vweb.Context
	user_db  map[string]string @[required]
	root_dir pathlib.Path      @[vweb_global]
pub mut:
	lock_manager LockManager
	server_port int
	middlewares map[string][]vweb.Middleware
}

@[params]
pub struct AppArgs {
pub mut:
	server_port int = 8080
	root_dir    string            @[required]
	user_db     map[string]string @[required]
}

pub fn new_app(args AppArgs) !&App {
	root_dir := pathlib.get_dir(path: args.root_dir, create: true)!
	mut app := &App{
		user_db: args.user_db.clone()
		root_dir: root_dir
		server_port: args.server_port
	}

	app.middlewares['/'] << logging_middleware
	app.middlewares['/'] << app.auth_middleware

	return app
}

@[params]
pub struct RunArgs {
pub mut:
	background bool
}

pub fn (mut app App) run(args RunArgs) {
	console.print_green('Running the server on port: ${app.server_port}')
	if args.background {
		spawn vweb.run(app, app.server_port)
	} else {
		vweb.run(app, app.server_port)
	}
}

pub fn (mut app App) not_found() vweb.Result {
	app.set_status(404, 'Not Found')
	return app.html('<h1>Page not found</h1>')
}
