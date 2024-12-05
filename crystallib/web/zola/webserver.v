module zola

import vweb
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.osal
import os
import freeflowuniverse.crystallib.ui.console

pub struct App {
	vweb.Context
	path pathlib.Path @[vweb_global]
}

@['/:path...']
pub fn (mut app App) index(path string) vweb.Result {
	if path == '/' {
		return app.html(os.read_file('${app.path.path}/index.html') or {
			return app.server_error(500)
		})
	}
	if !path.all_after_last('/').contains('.') {
		return app.html(os.read_file('${app.path.path}${path}/index.html') or {
			return app.not_found()
		})
	}
	return app.not_found()
}

@[params]
pub struct ServeParams {
	port int  = 9998
	open bool = true
}

pub fn (mut site ZolaSite) serve(params ServeParams) ! {
	mut app := App{
		path: site.path_publish
	}
	app.mount_static_folder_at('${site.path_publish.path}', '/')
	spawn vweb.run(&app, params.port)
	if params.open {
		osal.exec(cmd: 'open http://localhost:${params.port}')!
	}
	console.print_debug('webserver for zola running.')
	for {}
}
