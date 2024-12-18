module http

pub fn authenticator_handle(portal_name string) Handle {
	return Handle{
		handler:       'authenticator'
		portal_name:   portal_name
		route_matcher: '*'
	}
}

pub fn authentication_handle(policy_name string) Handle {
	return Handle{
		handler:   'authentication'
		providers: Providers{
			authorizer: Authorizer{
				gatekeeper_name: policy_name
				route_matcher:   '*'
			}
		}
	}
}

pub fn reverse_proxy_handle(upstreams []string) Handle {
	mut upstreams_maps := []map[string]string{}
	for upstream in upstreams {
		upstreams_maps << {
			'dial': upstream
		}
	}

	return Handle{
		handler:   'reverse_proxy'
		upstreams: upstreams_maps
	}
}

pub fn basic_auth_handle(username string, password string) !Handle {
	return Handle{
		handler:   'authentication'
		providers: Providers{
			http_basic: HTTPBasic{
				accounts: [
					Account{
						username: username
						password: hash_password(password)!
					},
				]
				hash:     Hash{'bcrypt'}
			}
		}
	}
}
