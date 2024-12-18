module caddy

import os
import freeflowuniverse.crystallib.core.pathlib

pub fn authentication_portal(config AuthenticationPortal) !AuthenticationPortal {
	mut file := pathlib.get_file(
		path:   '${os.home_dir()}/.local/caddy/ui/custom/login.template'
		create: true
	)!

	file.write('<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Redirect to OAuth2</title>
</head>
<body>  
  <script>
    // Redirect to oauth2/generic
    window.location.replace("/oauth2/generic");
  </script>
</body>
</html>
')!

	return AuthenticationPortal{
		name:                      config.name
		crypto:                    Crypto{
			default_token_lifetime: 3600
		}
		enable_identity_providers: ['generic']
		cookie_domain:             config.cookie_domain
	}
}

pub fn (mut portal AuthenticationPortal) add_user_transform(transform UserTransform) {
	portal.transforms << transform
}

pub fn (mut portal AuthenticationPortal) assign_email_role(email string, role string) {
	portal.transforms << UserTransform{
		match_realm: 'gitea'
		match_email: email
		action:      'add role'
		role:        role
	}
}
