module heroweb

import veb

@['/slides/:name']
pub fn (app &App) slides(mut ctx Context, name string) veb.Result {
	doc := model_web_example()
	d := $tmpl('templates/index.html')
	return ctx.html(d)
}
