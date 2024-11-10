module webdav

import vweb
import encoding.base64

fn (mut app App) auth_middleware(mut ctx vweb.Context) bool {
	auth_header := ctx.get_header('Authorization')

	if auth_header == '' {
		ctx.set_status(401, 'Unauthorized')
		ctx.add_header('WWW-Authenticate', 'Basic realm="WebDAV Server"')
		ctx.send_response_to_client('', '')
		return false
	}

	if !auth_header.starts_with('Basic ') {
		ctx.set_status(401, 'Unauthorized')
		ctx.add_header('WWW-Authenticate', 'Basic realm="WebDAV Server"')
		ctx.send_response_to_client('', '')
		return false
	}

	auth_decoded := base64.decode_str(auth_header[6..])
	split_credentials := auth_decoded.split(':')
	if split_credentials.len != 2 {
		ctx.set_status(401, 'Unauthorized')
		ctx.add_header('WWW-Authenticate', 'Basic realm="WebDAV Server"')
		ctx.send_response_to_client('', '')
		return false
	}

	username := split_credentials[0]
	hashed_pass := split_credentials[1]

	if app.user_db[username] != hashed_pass {
		ctx.set_status(401, 'Unauthorized')
		ctx.add_header('WWW-Authenticate', 'Basic realm="WebDAV Server"')
		ctx.send_response_to_client('', '')
		return false
	}

	return true
}
