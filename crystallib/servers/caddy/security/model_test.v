module security

import json
import os
import freeflowuniverse.crystallib.core.pathlib

// const testdata_dir = pathlib.get_dir(path: '${os.dir(@FILE)}/testdata')!
// const testdata_dir = pathlib.get_dir(path: '${os.dir(@FILE)}/testdata')!

const security_object = Security{
	config: Config{
		credentials:            {}
		authentication_portals: [
			AuthenticationPortal{
				name:                     'myportal'
				ui:                       UIConfig{
					theme:                     ''
					templates:                 {}
					allow_role_selection:      false
					title:                     ''
					logo_url:                  ''
					logo_description:          ''
					private_links:             [
						PrivateLink{
							link:            '/whoami'
							title:           'My Identity'
							style:           ''
							open_new_window: false
							target:          ''
							target_enabled:  false
							icon_name:       'las la-user'
							icon_enabled:    true
						},
					]
					auto_redirect_url:         ''
					realms:                    []
					password_recovery_enabled: false
					custom_css_path:           ''
					custom_js_path:            ''
				}
				user_registration_config: UserRegistrationConfig{
					disabled:              false
					title:                 ''
					code:                  ''
					dropbox:               ''
					require_accept_terms:  false
					require_domain_mx:     false
					terms_conditions_link: ''
					privacy_policy_link:   ''
					email_provider:        ''
					admin_emails:          []
				}
				user_transformer_configs: [
					UserTransformerConfig{
						matchers: ['exact match realm gitea', 'exact match email gitea']
						actions:  ['action add role role admin']
					},
				]
				cookie_config:            CookieConfig{
					domains:   {
						'ourworld.tf': DomainConfig{
							seq:       1
							domain:    'ourworld.tf'
							path:      ''
							lifetime:  0
							insecure:  false
							same_site: ''
						}
					}
					path:      ''
					lifetime:  0
					insecure:  false
					same_site: ''
				}
				identity_stores:          []
				identity_providers:       [
					'generic',
				]
				access_list_configs:      []
				token_validator_options:  TokenValidatorOptions{
					validate_source_address:         false
					validate_bearer_header:          false
					validate_method_path:            false
					validate_access_list_path_claim: false
				}
				crypto_key_configs:       [
					CryptoKeyConfig{
						seq:               0
						id:                '0'
						usage:             'sign-verify'
						token_name:        'access_token'
						source:            'config'
						algorithm:         'hmac'
						env_var_name:      ''
						env_var_type:      ''
						env_var_value:     ''
						file_path:         ''
						dir_path:          ''
						token_lifetime:    3600
						token_secret:      'u7XjDawOgGijydKxa5kK2uKONsaFalljkcXsLTuY/UM='
						token_sign_method: ''
						token_eval_expr:   []
					},
				]
				crypto_key_store_config:  {
					'token_lifetime': ''
				}
				token_grantor_options:    TokenGrantorOptions{
					enable_source_address: false
				}
				api:                      APIConfig{
					enabled: false
				}
			},
		]
		authorization_policies: [
			AuthorizationPolicy{
				name:                            'mypolicy'
				auth_url_path:                   'https://auth.projectinca.xyz/oauth2/generic'
				disable_auth_redirect:           false
				disable_auth_redirect_query:     false
				auth_redirect_query_param:       'redirect_url'
				auth_redirect_status_code:       302
				redirect_with_javascript:        false
				bypass_configs:                  []
				header_injection_configs:        []
				access_list_rules:               [
					AccessListConfig{
						comment:    ''
						conditions: ['match roles authp/admin authp/user']
						action:     'allow log debug'
					},
				]
				crypto_key_configs:              [
					CryptoKeyConfig{
						seq:               0
						id:                '0'
						usage:             'verify'
						token_name:        'access_token'
						source:            'config'
						algorithm:         'hmac'
						env_var_name:      ''
						env_var_type:      ''
						env_var_value:     ''
						file_path:         ''
						dir_path:          ''
						token_lifetime:    900
						token_secret:      'env.JWT_SHARED_KEY'
						token_sign_method: ''
						token_eval_expr:   []
					},
				]
				crypto_key_store_config:         {}
				auth_proxy_config:               {}
				allowed_token_sources:           []
				strip_token_enabled:             false
				forbidden_url:                   ''
				user_identity_field:             ''
				validate_bearer_header:          true
				validate_method_path:            false
				validate_access_list_path_claim: false
				validate_source_address:         false
				pass_claims_with_headers:        true
				login_hint_validators:           []
			},
		]
		messaging:              MessagingConfig{
			email_providers: []
			file_providers:  []
		}
		identity_stores:        []
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

pub fn test_json_decode() {
	mut file := pathlib.get_file(path: '${os.dir(@FILE)}/testdata/security.json')!
	security_json := file.read()!
	security_json_decoded := json.decode(Security, security_json) or { panic(err) }
	assert security_json_decoded == security_object
}
