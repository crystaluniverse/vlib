module components

// import nedpals.vex.ctx
// import nedpals.vex.session
// import nedpals.vex.router
import freeflowuniverse.crystallib.ui.console

// @[table: 'Session']
// @[params]
// pub struct Session {
// pub mut:
// 	id             int    @[primary; sql: serial]
// 	email          string
// 	description    string
// 	firstname      string @[nonull]
// 	lastname       string @[nonull]
// 	company        string
// 	email_verified bool
// }

// // pub fn (o Session) html() ! string{

// // 	out:=$tmpl("templates/session.html")
// // 	return out

// // }

// pub fn login_new(req &ctx.Req, mut res ctx.Resp) {
// 	mut ses := session.start(req, mut res)

// 	// if there is already a session set, then redirect to the profile page
// 	if !ses.is_empty() {
// 		res.redirect('/profile')
// 		return
// 	}

// 	res.send_html('', 200)
// }

// // on login post
// pub fn login_post(req &ctx.Req, mut res ctx.Resp) {
// 	post_data := req.parse_form() or {
// 		console.print_debug('Failed to parse form data.')
// 		return
// 	}

// 	mut ses := session.start(req, mut res)
// 	ses.set('email', post_data['email'])
// 	ses.set('password', post_data['password'])

// 	res.redirect('/profile')
// }

// pub fn app_add_login(mut app router.Router) ! {
// 	// app.route(.get, '/profile', profile)
// 	app.route(.get, '/login', login_new)
// 	app.route(.post, '/login', login_post)
// 	// app.route(.post, '/logout', logout_post)
// }
