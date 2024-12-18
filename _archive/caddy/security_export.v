module caddy

import os

pub fn (s Security) export() SiteBlock {
	mut site_block := SiteBlock{}

	// Add HTTPS port directive
	site_block.directives << Directive{
		name: 'https_port'
		args: [s.https_port.str()]
	}

	// Add order directives
	for order in s.orders {
		site_block.directives << Directive{
			name: 'order'
			args: [order.directive1, 'before', order.directive2]
		}
	}

	// Add security block directives
	site_block.directives << Directive{
		name:          'security'
		subdirectives: [
			// OAuth provider subdirective
			s.oauth_provider.to_directive(),
			// Authentication portal subdirective
			s.authentication.to_directive(),
			// Authorization policy subdirective
			s.authorization.to_directive(),
		]
	}

	return site_block
}

pub fn (oauth_provider OAuthProvider) to_directive() Directive {
	mut subdirectives := [
		Directive{
			name: 'realm'
			args: [oauth_provider.realm]
		},
		Directive{
			name: 'driver'
			args: [oauth_provider.driver]
		},
		Directive{
			name: 'domain_name'
			args: [oauth_provider.domain_name]
		},
		Directive{
			name: 'client_id'
			args: [oauth_provider.client_id]
		},
		Directive{
			name: 'client_secret'
			args: [oauth_provider.client_secret]
		},
		Directive{
			name: 'scopes'
			args: oauth_provider.scopes
		},
		Directive{
			name: 'base_auth_url'
			args: [oauth_provider.base_auth_url]
		},
		Directive{
			name: 'metadata_url'
			args: [oauth_provider.metadata_url]
		},
		// Add user group filters if any
	]
	subdirectives << oauth_provider.user_group_filters.map(Directive{
		name: 'user_group_filters'
		args: [
			it,
		]
	})

	return Directive{
		name:          'oauth identity provider ${oauth_provider.driver}'
		subdirectives: subdirectives
	}
}

pub fn (transform UserTransform) to_directive() Directive {
	mut subdirectives := [
		Directive{
			name: 'match realm'
			args: [transform.match_realm]
		},
	]
	if transform.match_email.len > 0 {
		subdirectives << Directive{
			name: 'match email'
			args: [transform.match_email]
		}
	}

	subdirectives << Directive{
		name: 'action'
		args: [transform.action, 'role', transform.role]
	}

	if transform.ui_link.label.len > 0 {
		subdirectives << Directive{
			name: 'ui link'
			args: ['"${transform.ui_link.label}"', '"${transform.ui_link.url}"', 'icon',
				'"${transform.ui_link.icon}"']
		}
	}

	return Directive{
		name:          'transform user'
		subdirectives: subdirectives
	}
}

pub fn (crypto Crypto) to_directives() []Directive {
	mut directives := []Directive{}

	if crypto.default_token_lifetime != 0 {
		directives << Directive{
			name: 'crypto default token lifetime'
			args: [crypto.default_token_lifetime.str()]
		}
	}

	if crypto.sign_verify_key != '' {
		directives << Directive{
			name: 'crypto key sign-verify'
			args: [crypto.sign_verify_key]
		}
	}
	return directives
}

pub fn (authentication AuthenticationPortal) to_directive() Directive {
	mut subdirectives := authentication.crypto.to_directives()

	for provider in authentication.enable_identity_providers {
		subdirectives << Directive{
			name: 'enable identity provider'
			args: [provider]
		}
	}

	subdirectives << Directive{
		name: 'cookie domain'
		args: [authentication.cookie_domain]
	}
	subdirectives << Directive{
		name:          'ui'
		subdirectives: [
			Directive{
				name: 'template'
				args: ['login', '${os.home_dir()}/.local/caddy/ui/custom/login.template']
			},
		]
	}

	for transform in authentication.transforms {
		subdirectives << transform.to_directive()
	}

	return Directive{
		name:          'authentication portal ${authentication.name}'
		subdirectives: subdirectives
	}
}

pub fn (authorization AuthorizationPolicy) to_directive() Directive {
	mut subdirectives := [
		Directive{
			name: 'set auth url'
			args: [authorization.auth_url]
		},
		Directive{
			name: 'allow roles'
			args: authorization.allowed_roles
		},
		Directive{
			name: 'validate bearer'
			args: [if authorization.validate_bearer { 'header' } else { 'header' }]
		},
		Directive{
			name: 'inject headers'
			args: [if authorization.inject_headers { 'with claims' } else { 'with claims' }]
		},
	]

	if authorization.crypto_key_verify != '' {
		subdirectives << Directive{
			name: 'crypto key verify'
			args: [authorization.crypto_key_verify]
		}
	}

	return Directive{
		name:          'authorization policy ${authorization.name}'
		subdirectives: subdirectives
	}
}

pub fn (link UILink) to_directive() Directive {
	return Directive{
		name: ''
		args: ['"${link.label}"', '"${link.url}"', 'icon', '"${link.icon}"']
	}
}
