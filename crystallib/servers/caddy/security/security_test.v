module security

pub fn test_add_role() ! {
	mut s := Security{}

	s.add_oauth(
		name:          'gitea'
		domain:        'git.ourworld.tf'
		client_id:     'client_id'
		client_secret: 'client_secret'
	)!

	s.add_role('admin', ['example@example.com'])!

	assert s == Security{
		config: Config{
			authentication_portals: [
				AuthenticationPortal{
					name:                     'gitea'
					ui:                       UIConfig{
						templates: {
							'login': '/Users/timurgordon/.local/caddy/ui/custom/login.template'
						}
					}
					user_transformer_configs: [
						UserTransformerConfig{
							matchers: ['exact match email example@example.com']
							actions:  ['action add role admin']
						},
					]
					cookie_config:            CookieConfig{
						domains: {
							'git.ourworld.tf': DomainConfig{
								domain: 'git.ourworld.tf'
							}
						}
					}
					identity_providers:       [
						'generic',
					]
					crypto_key_configs:       [
						CryptoKeyConfig{
							usage:             'sign-verify'
							token_name:        'access_token'
							source:            'config'
							algorithm:         'hmac'
							token_lifetime:    3600
							token_secret:      'u7XjDawOgGijydKxa5kK2uKONsaFalljkcXsLTuY/UM='
							token_sign_method: ''
							token_eval_expr:   []
						},
					]
				},
			]
			identity_providers:     [
				IdentityProvider{
					name:   'generic'
					kind:   'oauth'
					params: {
						'base_auth_url': 'https://git.ourworld.tf/login/oauth/authorize'
						'client_id':     'client_id'
						'client_secret': 'client_secret'
						'domain_name':   'git.ourworld.tf'
						'driver':        'generic'
						'metadata_url':  'https://git.ourworld.tf/.well-known/openid-configuration'
						'realm':         'generic'
						'scopes':        ''
					}
				},
			]
		}
	}
}
