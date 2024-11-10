module webdav

import vweb
import freeflowuniverse.crystallib.ui.console

fn logging_middleware(mut ctx vweb.Context) bool {
	console.print_green('=== New Request ===')
	console.print_green('Method: ${ctx.req.method.str()}')
	console.print_green('Path: ${ctx.req.url}')
	console.print_green('Headers: ${ctx.req.header}')
	console.print_green('')
	return true
}
