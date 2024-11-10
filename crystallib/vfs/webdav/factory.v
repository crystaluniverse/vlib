module webdav

import vweb

@[params]
pub struct WebDAVParams {
pub:
	path string @[required] // root directory path for WebDAV server
	port int = 8080       // port to run the server on, defaults to 8080
}

pub fn start(params WebDAVParams) ! {
	// Implementation will be added here
	mut myapp := new_app(
		params.path
	)!

	vweb.run(myapp, 8080)
}
