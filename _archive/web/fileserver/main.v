module main

import vweb
import freeflowuniverse.crystallib.installers.web.caddy as caddyinstaller
import freeflowuniverse.crystallib.web.auth
import os

pub struct FileServer {
	vweb.Context
	auth auth.Authenticator
}

pub fn main() {
	do() or { panic(err) }
}

pub fn (mut server FileServer) before_request() {
	access_token := server.get_access_token() or { app.redirect('/login') }
	user := server.authenticate_user(access_token) or { app.redirect('/login') }
	if !server.user_is_authorized(user) {
		app.redirect('/unauthorized')
	}
}

pub fn (server FileServer) get_access_token() ? {
	if access_token.is_expired() {
		refresh_token_str := app.get_cookie('refresh_token') or { '' }
		access_token_str = app.session_client.new_access_token(refresh_token_str) or { panic(err) }
		app.set_cookie(name: 'access_token', value: access_token_str)
	}
	server.session_auth.authenticate_access_token()
}

pub fn (app FileServer) authenticate_user() ? {
	if access_token.is_expired() {
		refresh_token_str := app.get_cookie('refresh_token') or { '' }
		access_token_str = app.session_auth.new_access_token(refresh_token_str) or { panic(err) }
		app.set_cookie(name: 'access_token', value: access_token_str)
	}
	app.session_auth.authenticate_access_token()
}

pub fn do() ! {
	mut server := new_server()
	server.serve()!
}

pub fn new_server(paths []string) FileServer {
	return FileServer{}
}

pub fn (mut server FileServer) serve() ! {
	caddyfile_path := os.dir(@FILE) + '/Caddyfile'
	caddyinstaller.configuration_set(path: caddyfile_path)!
	mut zprocess := caddyinstaller.restart()!
	vweb.run(server, 8080)
}

pub fn (mut server FileServer) index() vweb.Result {
	return $vweb.html()
}

pub fn (mut server FileServer) file() vweb.Result {
}
