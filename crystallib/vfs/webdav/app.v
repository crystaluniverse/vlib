module webdav

import vweb
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.ui.console
import rand

@[heap]
struct App {
	vweb.Context
	username string @[required]
	password string @[required]
	root_dir pathlib.Path      @[vweb_global]
pub mut:
	server_port int
	middlewares map[string][]vweb.Middleware
}

@[params]
pub struct AppArgs {
pub mut:
	server_port int = rand.int_in_range(8000, 9000)!
	root_dir string @[required]
	username string @[required]
	password string @[required]
}

pub fn new_app(args AppArgs) !&App {
	root_dir := pathlib.get_dir(path: args.root_dir, create: true)!
	mut app := &App{
		username: args.username,
		password: args.password,
		root_dir: root_dir,
		server_port: args.server_port,
	}

	app.middlewares['/'] << logging_middleware
	app.middlewares['/'] << app.auth_middleware

	return app
}

@[params]
pub struct RunArgs {
pub mut:
	spawn_ bool
}

pub fn (mut app App) run(args RunArgs) {
	console.print_green('Running the server on port: ${app.server_port}')
	if args.spawn_{
		spawn vweb.run(app, app.server_port)
	} else {
		vweb.run(app, app.server_port)
	}
}

pub fn (mut app App) not_found() vweb.Result {
	app.set_status(404, 'Not Found')
	return app.html('<h1>Page not found</h1>')
}
