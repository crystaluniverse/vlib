module http

import freeflowuniverse.crystallib.osal

pub fn (mut h HTTP) add_route(route string, handles []Handle) ! {
	if 'srv0' !in h.servers {
		h.servers['srv0'] = Server{
			listen: [':443']
		}
	}
	h.servers['srv0'].routes << Route{
		@match: [
			Match{
				host: [route]
			},
		]
		handle: [
			Handle{
				handler: 'subroute'
				routes:  [
					Route{
						@match: [
							Match{
								path: ['*']
							},
						]
						handle: [
							Handle{
								handler: 'subroute'
								routes:  [Route{
									handle: handles
								}]
							},
						]
					},
				]
			},
		]
	}
}

pub fn (mut h HTTP) add_file_server(args FileServer) ! {
	if 'srv0' !in h.servers {
		h.servers['srv0'] = Server{}
	}

	h.servers['srv0'].routes << Route{
		@match: [Match{
			host: [args.domain]
		}]
		handle: [
			Handle{
				handler: 'subroute'
				routes:  [
					Route{
						handle: [
							Handle{
								handler: 'vars'
								root:    args.root
							},
							Handle{
								handler: 'file_server'
								hide:    ['/etc/caddy/Caddyfile']
							},
						]
					},
				]
			},
		]
	}
}

@[params]
pub struct ReverseProxy {
pub:
	from string // path on which the url will be proxied on the domain
	to   string // url that is being reverse proxied
}

pub fn (mut h HTTP) add_reverse_proxy(args ReverseProxy) ! {
	if 'srv0' !in h.servers {
		h.servers['srv0'] = Server{}
	}

	h.servers['srv0'].routes << Route{
		@match: [Match{
			host: [args.to]
		}]
		handle: [
			Handle{
				handler: 'subroute'
				routes:  [
					Route{
						handle: [
							reverse_proxy_handle([args.from]),
						]
					},
				]
			},
		]
	}
}

pub struct BasicAuth {
pub:
	domain   string
	username string
	password string
}

pub fn (mut h HTTP) add_basic_auth(args BasicAuth) ! {
	for key, mut server in h.servers {
		server.add_basic_auth(args.domain, args.username, args.password)!
	}
}

pub fn (mut server Server) add_basic_auth(domain string, username string, password string) ! {
	for mut route in server.routes {
		if route.@match.any(domain in it.host) {
			route.add_basic_auth(username, password)!
		}
	}
}

pub fn (mut route Route) add_basic_auth(username string, password string) ! {
	mut found := false
	for mut handle in route.handle {
		if handle.handler == 'subroute' {
			found = true
			mut routes := handle.routes.clone()
			for mut r in routes {
				mut inserted := false
				for i, h in r.handle {
					// for some reason this needs to be placed after vars handler
					if h.handler == 'vars' {
						r.handle.insert(i + 1, basic_auth_handle(username, password)!)
						inserted = true
					}
				}
				if !inserted {
					r.handle.prepend(basic_auth_handle(username, password)!)
				}
			}
			handle.routes = routes.clone()
		}
	}
	if !found {
		route.handle << Handle{
			handler: 'subroute'
			routes:  [
				Route{
					handle: [basic_auth_handle(username, password)!]
				},
			]
		}
	}
}

@[params]
pub struct HashPasswordParams {
	algorithm string = 'bcrypt'
}

pub fn hash_password(plaintext string, params HashPasswordParams) !string {
	if plaintext == '' {
		return error('plaintext cannot be empty')
	}
	result := osal.exec(cmd: 'caddy hash-password -p ${plaintext}')!
	return result.output.trim_space()
}

pub struct FileServer {
pub:
	domain string // path on which the url will be proxied on the domain
	root   string // url that is being reverse proxied
}
