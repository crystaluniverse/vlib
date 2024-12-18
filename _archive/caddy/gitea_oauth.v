module caddy

// Endpoint	URL
// OpenID Connect Discovery	/.well-known/openid-configuration
// Authorization Endpoint	/login/oauth/authorize
// Access Token Endpoint	/login/oauth/access_token
// OpenID Connect UserInfo	/login/oauth/userinfo
// JSON Web Key Set	/login/oauth/keys

pub struct GiteaOAuth {
pub:
	domain        string
	client_id     string
	client_secret string
	scopes        []OpenIDScopes
}

// pub enum GiteaScopes {
// 	OpenIDScopes
// }

pub enum OpenIDScopes {
	profile
	email
	address
	phone
}

// // Returns a caddy-security OAuth provider model for gitea
// pub fn gitea_oauth_provider(config GiteaOAuth) OAuthProvider {
// 	return OAuthProvider{
// 		realm: 'generic'
// 		driver: 'generic'
// 		domain_name: config.domain
// 		client_id: config.client_id
// 		client_secret: config.client_secret
// 		scopes: config.scopes.map(it.str())
// 		base_auth_url: 'https://${config.domain}/login/oauth/authorize'
// 		metadata_url: 'https://${config.domain}/.well-known/openid-configuration'
// 		user_group_filters: []
// 	}
// }
