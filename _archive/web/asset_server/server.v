module resources

import vweb
import freeflowuniverse.crystallib.web.auth { Authenticator }
import freeflowuniverse.crystallib.web.auth_server
import freeflowuniverse.crystallib.core.pathlib
import log

@[noinit]
pub struct ResourceServer {
	vweb.Context
pub mut:
	auth   auth_server.Client
	assets []Resource         @[required; vweb_global]
	logger &log.Logger = &log.Logger(&log.Log{
	level: .debug
})        @[vweb_global]
}

pub struct Resource {
	name string
	path string
	acl  auth.AccessControlList
}

pub struct ResourceServerConfig {
	auth   Authenticator @[required] // Authenticator to be used
	assets []Resource    @[required]
	logger log.Logger
}

// new_asset_server configures and creates a new resource server
pub fn new(config ResourceServerConfig) !ResourceServer {
	mut access := map[string]auth.AccessControlList{}

	for resource in config.assets {
		access[resource.name] = resource.acl
	}

	authenticator := Authenticator{
		...config.auth
		access: access
	}
	mut server := ResourceServer{
		auth: authenticator
		assets: config.assets
	}

	for resource in config.assets {
		source := pathlib.get(resource.path).absolute()
		mount := '/${resource.name}'
		server.mount_static_folder_at(source, mount)
	}
	return server
}

// before_request is a middleware that authorizes all requests made to resource endpoints
pub fn (mut server ResourceServer) before_request() {
	server.auth.Context = server.Context

	authorized_urls := ['/', '/favicon.ico']
	if server.req.url !in authorized_urls {
		resource := server.req.url.trim_string_left('/').all_before('/')
		server.logger.info('Attempt to access resource: ${resource}')
		if !server.assets.any(it.name == resource) {
			server.logger.error('Resource ${resource} not found')
			server.not_found()
		}

		if user := server.auth.get_user() {
			if !server.auth.authorize(
				accessor: user.email
				asset_id: resource
				access_type: .read
			) {
				server.logger.error('Unauthorized access attempt to resource ${resource}')
				server.server_error(403)
			}
		} else {
			server.logger.error('User not logged in')
			server.server_error(403)
		}
	}
}

// wildcard path that handles all requests to assets
@['/:path...']
pub fn (mut server ResourceServer) index(path string) vweb.Result {
	return server.html('ok')
}

pub fn (mut server ResourceServer) not_found() vweb.Result {
	server.set_status(404, 'Not Found')
	return server.html($tmpl('./templates/404.html'))
}
