module webdav

import vweb

fn logging_middleware(mut ctx vweb.Context) bool {
	println('=== New Request ===')
	println('Method: ${ctx.req.method.str()}')
	println('Path: ${ctx.req.url}')
	println('Headers: ${ctx.header}')
	println('')
	return true
}
