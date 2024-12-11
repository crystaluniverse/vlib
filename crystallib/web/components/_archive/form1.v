module components

import db.sqlite
// import nedpals.vex.ctx
// import nedpals.vex.router
import context
import freeflowuniverse.crystallib.ui.console

// @[table: 'Form1']
// @[params]
// pub struct Form1 {
// pub mut:
// 	id          int    @[primary; sql: serial]
// 	title       string
// 	description string
// 	firstname   string @[nonull]
// 	lastname    string @[nonull]
// 	company     string
// 	email       string
// 	subject     string
// 	message     string
// }

// pub fn (o Form1) html() !string {
// 	out := $tmpl('templates/form1.html')
// 	return out
// }

// pub fn form1_get(req &ctx.Req, mut res ctx.Resp) {
// 	mut out := html_pre(req)!

// 	db := get_db(req) or {
// 		res.send_status(500)
// 		return
// 	}

// 	nr := sql db {
// 		select count from Form1
// 	}!
// 	if nr == 0 {
// 		o := Form1{}
// 		sql db {
// 			insert o into Form1
// 		}!
// 	}

// 	out += html_post(req)!

// 	res.send_html(out, 200)
// }

// pub fn form1_post(req &ctx.Req, mut res ctx.Resp) {
// 	post_data := req.parse_form() or {
// 		console.print_debug('Failed to parse form data.')
// 		return
// 	}

// 	mut ses := session.start(req, mut res)
// 	ses.set('email', post_data['email'])
// 	ses.set('password', post_data['password'])

// 	res.redirect('/profile')
// }

// pub fn app_add_form1(app router.Router) ! {
// 	sql db {
// 		create table Form1
// 	}!

// 	app.route(.get, '/form1/', form1_get)
// 	app.route(.post, '/form1/', form1_post)
// }
