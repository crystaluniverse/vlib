module caddy

fn test_export_security() {
	// Define a sample Security configuration to export
	security := Security{
		https_port:     443
		orders:         [
			Order{'authenticate', 'respond'},
			Order{'authorize', 'basicauth'},
		]
		oauth_provider: OAuthProvider{
			realm:              'generic'
			driver:             'generic'
			domain_name:        'git.ourworld.tf'
			client_id:          'some_client_id'
			client_secret:      'some_client_secret'
			scopes:             ['openid', 'email', 'profile']
			base_auth_url:      'https://git.ourworld.tf/login/oauth/authorize'
			metadata_url:       'https://git.ourworld.tf/.well-known/openid-configuration'
			user_group_filters: ['barfoo', '^a']
		}
		authentication: AuthenticationPortal{
			name:                      'myportal'
			crypto:                    Crypto{
				default_token_lifetime: 3600
				sign_verify_key:        'some_crypto_key'
			}
			enable_identity_providers: ['generic']
			cookie_domain:             'ourworld.tf'
			ui_links:                  [
				UILink{
					label: 'My Identity'
					url:   '/whoami'
					icon:  'las la-user'
				},
			]
			transforms:                [
				UserTransform{
					match_realm: 'gitea'
					action:      'add'
					role:        'authp/user'
				},
				UserTransform{
					match_realm: 'gitea'
					action:      'add'
					role:        'authp/admin'
				},
			]
		}
		authorization:  AuthorizationPolicy{
			auth_url:          'https://auth.projectinca.xyz/oauth2/generic'
			crypto_key_verify: 'some_jwt_key'
			allowed_roles:     ['authp/admin', 'authp/user']
			validate_bearer:   true
			inject_headers:    true
		}
	}

	// Print the exported result for validation
	assert security.export() == SiteBlock{
		addresses:  []
		directives: [
			Directive{
				name:          'https_port'
				args:          ['443']
				matchers:      []
				subdirectives: []
			},
			Directive{
				name:          'order'
				args:          ['authenticate', 'before', 'respond']
				matchers:      []
				subdirectives: []
			},
			Directive{
				name:          'order'
				args:          ['authorize', 'before', 'basicauth']
				matchers:      []
				subdirectives: []
			},
			Directive{
				name:          'security'
				args:          []
				matchers:      []
				subdirectives: []
			},
		]
	}
	panic(security.export().directives.filter(it.name == 'security').map(it.subdirectives))
}
