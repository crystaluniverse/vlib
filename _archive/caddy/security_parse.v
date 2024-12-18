module caddy

pub fn parse_security(site_block SiteBlock) !Security {
	mut security := Security{}

	for directive in site_block.directives {
		match directive.name {
			'https_port' {
				security.https_port = directive.args[0].int()
			}
			'order' {
				security.orders << Order{
					directive1: directive.args[0]
					directive2: directive.args[2]
				}
			}
			'security' {
				for subdirective in directive.subdirectives {
					match subdirective.name {
						'oauth identity provider' {
							security.oauth_provider = parse_oauth_provider(subdirective)!
						}
						'authentication portal' {
							security.authentication = parse_authentication_portal(subdirective)!
						}
						'authorization policy' {
							security.authorization = parse_authorization_policy(subdirective)!
						}
						else {}
					}
				}
			}
			else {}
		}
	}

	return security
}

fn parse_oauth_provider(subdirective Directive) !OAuthProvider {
	mut provider := OAuthProvider{}
	for sub in subdirective.subdirectives {
		match sub.name {
			'realm' { provider.realm = sub.args[0] }
			'driver' { provider.driver = sub.args[0] }
			'domain_name' { provider.domain_name = sub.args[0] }
			'client_id' { provider.client_id = sub.args[0] }
			'client_secret' { provider.client_secret = sub.args[0] }
			'scopes' { provider.scopes = sub.args }
			'base_auth_url' { provider.base_auth_url = sub.args[0] }
			'metadata_url' { provider.metadata_url = sub.args[0] }
			'user_group_filters' { provider.user_group_filters << sub.args[0] }
			else {}
		}
	}
	return provider
}

fn parse_authentication_portal(subdirective Directive) !AuthenticationPortal {
	mut portal := AuthenticationPortal{}
	for sub in subdirective.subdirectives {
		match sub.name {
			'name' {
				portal.name = sub.args[0]
			}
			'crypto default token lifetime' {
				portal.crypto.default_token_lifetime = sub.args[0].int()
			}
			'crypto key sign-verify' {
				portal.crypto.sign_verify_key = sub.args[0]
			}
			'enable identity provider' {
				portal.enable_identity_providers << sub.args[0]
			}
			'cookie domain' {
				portal.cookie_domain = sub.args[0]
			}
			'ui' {
				for ui_sub in sub.subdirectives {
					match ui_sub.name {
						'links' {
							for link_sub in ui_sub.subdirectives {
								portal.ui_links << parse_ui_link(link_sub)
							}
						}
						else {}
					}
				}
			}
			'transform user' {
				portal.transforms << parse_user_transform(sub.subdirectives)
			}
			else {}
		}
	}
	return portal
}

fn parse_user_transform(directives []Directive) UserTransform {
	mut match_realm := ''
	mut match_email := ''
	mut action := ''
	mut role := ''
	mut ui_link := UILink{}

	for directive in directives {
		match directive.name {
			'match realm' {
				if directive.args.len > 0 {
					match_realm = directive.args[0]
				}
			}
			'match email' {
				if directive.args.len > 0 {
					match_email = directive.args[0]
				}
			}
			'action add role', 'action remove role' {
				if directive.args.len > 0 {
					action = directive.name.split(' ')[0]
					role = directive.args[0]
				}
			}
			'ui link' {
				ui_link = parse_ui_link(directive)
			}
			else {}
		}
	}

	return UserTransform{
		match_realm: match_realm
		match_email: match_email
		action:      action
		role:        role
		ui_link:     ui_link
	}
}

fn parse_ui_link(directive Directive) UILink {
	return UILink{
		label: directive.name
		url:   if directive.args.len > 0 { directive.args[0] } else { '' }
		icon:  if directive.args.len > 2 { directive.args[2] } else { '' }
	}
}

fn parse_authorization_policy(subdirective Directive) !AuthorizationPolicy {
	mut policy := AuthorizationPolicy{}
	for sub in subdirective.subdirectives {
		match sub.name {
			'set auth url' { policy.auth_url = sub.args[0] }
			'crypto key verify' { policy.crypto_key_verify = sub.args[0] }
			'allow roles' { policy.allowed_roles = sub.args }
			'validate bearer' { policy.validate_bearer = sub.args[0] == 'header' }
			'inject headers' { policy.inject_headers = sub.args[0] == 'with claims' }
			else {}
		}
	}
	return policy
}
