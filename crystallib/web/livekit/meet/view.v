module meet

import veb

pub fn (app &App) index(mut ctx Context) veb.Result {
	dollar := '$'
	return ctx.html($tmpl('./templates/index.html'))
}

@['/rooms/room']
pub fn (app &App) room(mut ctx Context) veb.Result {
	dollar := '$'

	service_worker := $tmpl('./templates/service_worker.html')
	mut room_html := $tmpl('./templates/rooms/room.html')
	room_html = room_html.replace('<body>', '<body>\n${service_worker}')
	return ctx.html(room_html)
}

pub fn (app &App) custom(mut ctx Context) veb.Result {
	dollar := '$'
	return ctx.html($tmpl('./templates/custom.html'))
}

// Custom 404 handler
pub fn (mut ctx Context) not_found() veb.Result {
	ctx.res.set_status(.not_found)
	return ctx.html('<h1>Page not found!</h1>')
}