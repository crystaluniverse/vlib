module security

// import freeflowuniverse.crystallib.core.pathlib
import os

const login_template_path = '${os.home_dir()}/.local/caddy/ui/custom/login.template'

pub struct OAuthConfig {
pub:
	name          string
	domain        string
	client_id     string
	client_secret string
	scopes        []string
	token_secret  string @[required] // the secret used to encode decode auth token
}

pub fn (mut s Security) add_oauth(config OAuthConfig) ! {
	export_login_template(login_template_path)!

	mut scopes := config.scopes.clone()
	if 'openid' !in scopes {
		scopes << 'openid'
	}

	s = Security{
		config: Config{
			authentication_portals: [
				AuthenticationPortal{
					name:               config.name
					ui:                 UIConfig{
						templates: {
							'login': login_template_path
						}
					}
					cookie_config:      CookieConfig{
						domains: {
							config.domain: DomainConfig{
								domain: config.domain
							}
						}
					}
					identity_providers: ['generic']
					crypto_key_configs: [CryptoKeyConfig{
						usage:          'sign-verify'
						token_name:     'access_token'
						source:         'config'
						algorithm:      'hmac'
						token_lifetime: 3600
						token_secret:   config.token_secret
					}]
				},
			]
			identity_providers:     [
				IdentityProvider{
					name:   'generic'
					kind:   'oauth'
					params: Params{
						base_auth_url: 'https://${config.domain}'
						client_id:     config.client_id
						client_secret: config.client_secret
						domain_name:   config.domain
						driver:        'generic'
						metadata_url:  'https://${config.domain}/.well-known/openid-configuration'
						realm:         'generic'
						scopes:        scopes
					}
				},
			]
		}
	}
}

pub fn (mut s Security) add_role(role string, emails []string) ! {
	if s.config.authentication_portals.len == 0 {
		return error('There is no authentication defined.')
	}
	for mut portal in s.config.authentication_portals {
		for email in emails {
			portal.user_transformer_configs << UserTransformerConfig{
				matchers: ['exact match email ${email}']
				actions:  ['action add role ${role}']
			}
		}
	}
}

@[params]
pub struct PolicyParams {
pub mut:
	roles         []string
	auth_url_path string
	token_secret  string @[required]
}

pub fn (mut s Security) add_policy(name string, params PolicyParams) ! {
	s.config.authorization_policies << AuthorizationPolicy{
		name:               name
		access_list_rules:  [
			AccessListConfig{
				action:     'allow log debug'
				conditions: ['match roles ${params.roles.join(' ')}']
			},
		]
		crypto_key_configs: [
			CryptoKeyConfig{
				usage:          'sign-verify'
				token_name:     'access_token'
				source:         'config'
				algorithm:      'hmac'
				token_lifetime: 3600
				token_secret:   params.token_secret
			},
		]
		auth_url_path:      params.auth_url_path
	}
}
