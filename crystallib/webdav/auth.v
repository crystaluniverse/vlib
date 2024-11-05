module webdav

import vweb

fn (mut app App) auth_middleware(mut ctx vweb.Context) bool {
	return true
}
