#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import vweb
import os
import freeflowuniverse.crystallib.servers.caddy
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.installers.web.caddy as caddyinstaller

const auth_url = 'https://auth.some.url/oauth2/generic'

// Simple Hello World Webserver using vweb
struct App {
	vweb.Context
}

@['/hello']
pub fn (mut app App) hello() vweb.Result {
	return app.text('Hello, world!')
}

fn start_webserver() {
	vweb.run[App](App{}, 8080)
}

// Generate the Security configuration
fn generate_security_config() !caddy.Security {
	mut authentication := caddy.authentication_portal(
		name:          'myportal'
		cookie_domain: 'ourworld.tf'
	)!

	authentication.assign_email_role('timur@incubaid.com', 'admin')

	return caddy.Security{
		https_port:     443
		orders:         [
			caddy.Order{
				directive1: 'authenticate'
				directive2: 'respond'
			},
			caddy.Order{
				directive1: 'authorize'
				directive2: 'basicauth'
			},
		]
		oauth_provider: caddy.gitea_oauth_provider(
			domain:        'git.ourworld.tf'
			client_id:     os.getenv('GITEA_OAUTH_CLIENT_ID')
			client_secret: os.getenv('GITEA_OAUTH_CLIENT_SECRET')
			scopes:        [.email, .profile]
		)
		authentication: authentication
		authorization:  caddy.authorization_policy(
			name:          'mypolicy'
			auth_url:      auth_url
			allowed_roles: ['authp/admin', 'authp/user']
		)
	}
}

// install caddy
heroscript := "
!!caddy.install
    xcaddy:true
    restart:true
    reset:true
    homedir:'/root/www'
    xcaddy:1

"

// mut plbook := playbook.new(text: heroscript)!
// caddyinstaller.play(mut plbook)!

// Main function to set up the server and generate the Caddyfile

osal.load_env_file('${os.dir(@FILE)}/.env')!
// Start the webserver
spawn start_webserver()

// Generate the security configuration
security_config := generate_security_config()!

mut caddyfile := caddy.CaddyFile{
	path:        '${os.dir(@FILE)}/Caddyfile'
	site_blocks: [security_config.export()]
}

caddyfile.add_site_block(
	addresses:  [Address{
		domain: 'localhost'
		port:   8088
	}]
	directives: [
		Directive{
			name: 'authenticate'
			args: ['with myportal']
		},
		Directive{
			name: 'reverse_proxy'
			args: [':8080']
		},
	]
)

mut caddy_instance := caddy.configure('example',
	homedir: os.dir(@FILE)
	reset:   false
	file:    caddyfile
	plugins: ['github.com/greenpau/caddy-security']
) or { return error('Failed to configure Caddy instance: ${err}') }

// Export CaddyFile to file
caddyfile_content := caddyfile.export() or { panic(err) }
os.write_file('${os.dir(@FILE)}/Caddyfile', caddyfile_content) or { panic(err) }

// caddy_instance.restart()!

for {}
