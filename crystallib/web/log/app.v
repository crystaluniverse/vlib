module log

import db.sqlite
import veb

// pub struct App {
// 	Logger
// }

// pub struct Context {
// 	veb.Context
// }

// pub fn new_app(db_path string) !&App {
// 	return &App{
// 		Logger: log.new(
// 			DBBackend: log.new_backend(
// 				db: sqlite.connect(db_path)!
// 			)!
// 		)!
// 	}
// }

// pub fn (mut app App) index(mut ctx Context) veb.Result {
// 	return ctx.html('hello')
// } 