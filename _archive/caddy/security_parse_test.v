module caddy

fn test_parse_security() {
	// Define a sample CaddyFile to parse
	caddy_file := CaddyFile{
		site_blocks: [
			SiteBlock{
				directives: [
					Directive{
						name:          'security'
						subdirectives: [
							Directive{
								name:          'oauth identity provider'
								args:          ['generic']
								subdirectives: [Directive{
									name: 'realm'
									args: ['generic']
								}, Directive{
									name: 'driver'
									args: ['generic']
								}, Directive{
									name: 'domain_name'
									args: ['git.ourworld.tf']
								}, Directive{
									name: 'client_id'
									args: ['some_client_id']
								}, Directive{
									name: 'client_secret'
									args: ['some_client_secret']
								}, Directive{
									name: 'scopes'
									args: ['openid', 'email', 'profile']
								}, Directive{
									name: 'base_auth_url'
									args: ['https://git.ourworld.tf/login/oauth/authorize']
								}, Directive{
									name: 'metadata_url'
									args: [
										'https://git.ourworld.tf/.well-known/openid-configuration',
									]
								}]
							},
							Directive{
								name:          'authentication portal'
								args:          ['myportal']
								subdirectives: [Directive{
									name: 'crypto default token lifetime'
									args: [
										'3600',
									]
								}, Directive{
									name: 'crypto key sign-verify'
									args: [
										'some_crypto_key',
									]
								}, Directive{
									name: 'enable identity provider'
									args: [
										'generic',
									]
								}, Directive{
									name: 'cookie domain'
									args: [
										'ourworld.tf',
									]
								}, Directive{
									name:          'ui'
									subdirectives: [
										Directive{
											name:          'links'
											subdirectives: [
												Directive{
													name: 'My Identity'
													args: ['/whoami', 'icon', 'las la-user']
												},
											]
										},
									]
								}, Directive{
									name:          'transform user'
									subdirectives: [
										Directive{
											name: 'realm'
											args: [
												'gitea',
											]
										},
										Directive{
											name: 'add role'
											args: [
												'authp/user',
											]
										},
										Directive{
											name: 'add role'
											args: [
												'authp/admin',
											]
										},
									]
								}]
							},
							Directive{
								name:          'authorization policy'
								args:          ['mypolicy']
								subdirectives: [Directive{
									name: 'set auth url'
									args: [
										'https://auth.projectinca.xyz/oauth2/generic',
									]
								}, Directive{
									name: 'crypto key verify'
									args: [
										'some_jwt_key',
									]
								}, Directive{
									name: 'allow roles'
									args: [
										'authp/admin',
										'authp/user',
									]
								}, Directive{
									name: 'validate bearer'
									args: [
										'header',
									]
								}, Directive{
									name: 'inject headers'
									args: [
										'with claims',
									]
								}]
							},
						]
					},
				]
			},
		]
	}

	// Parse the CaddyFile into a Security struct
	security := parse_security(caddy_file.site_blocks[0])!

	// Print the export result for validation
	assert security == Security{
		https_port:     0
		orders:         []
		oauth_provider: OAuthProvider{
			realm:              'generic'
			driver:             'generic'
			domain_name:        'git.ourworld.tf'
			client_id:          'some_client_id'
			client_secret:      'some_client_secret'
			scopes:             ['openid', 'email', 'profile']
			base_auth_url:      'https://git.ourworld.tf/login/oauth/authorize'
			metadata_url:       'https://git.ourworld.tf/.well-known/openid-configuration'
			user_group_filters: []
		}
		authentication: AuthenticationPortal{
			name:                      ''
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
					match_realm: ''
					match_email: ''
					action:      ''
					role:        ''
					ui_link:     UILink{
						label: ''
						url:   ''
						icon:  ''
					}
				},
			]
		}
		authorization:  AuthorizationPolicy{
			name:              ''
			auth_url:          'https://auth.projectinca.xyz/oauth2/generic'
			crypto_key_verify: 'some_jwt_key'
			allowed_roles:     ['authp/admin', 'authp/user']
			validate_bearer:   true
			inject_headers:    true
		}
	}
}
