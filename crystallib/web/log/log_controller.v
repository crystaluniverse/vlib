module log

import json
import veb
import freeflowuniverse.crystallib.core.pathlib

// @[POST; '/log/:name']
// pub fn (mut app App) log_post(mut ctx Context, name string) veb.Result {
// 	infoptr := app.db.infopointers[name] or {
// 		return ctx.not_found()
// 	}

// 	new_log := json.decode(Log, ctx.req.data) or {
// 		return ctx.server_error(err.str())
// 	}
// 	app.db.logger.new_log(Log{...new_log, subject: ctx.user_id.str()}) or {
// 		return ctx.server_error(err.str())
// 	}

// 	return ctx.json('ok')
// }

// @[GET; '/logs']
// pub fn (mut app App) logs(mut ctx Context) veb.Result {
// 	// Initialize the query parameters if present
// 	mut query := 'SELECT * FROM Log WHERE'
//     event_filter := ctx.query['event'] or { '' }
// 	if event_filter != '' {
// 		query += ' event = ${event_filter}'
// 	}
    
// 	subject_filter := ctx.query['subject'] or { '' }
// 	if subject_filter != '' {
// 		query += ' subject = ${subject_filter}'
// 	}

// 	object_filter := ctx.query['object'] or { '' }
// 	if object_filter != '' {
// 		query += ' subject = ${object_filter}'
// 	}

// 	response := app.db.exec(query) or {
// 		return ctx.server_error(err.str())
// 	}

// 	if response.len == 0 {
// 		panic('response shouldnt be 0')
// 	}
// 	println('resp ${response}')

// 	// return response[0].vals

//     // Build the SQL query dynamically based on the provided filters
//     logs := sql app.db {
//         select from Log where 
//             object == object_filter &&
//             (event_filter == '' || event.contains(event_filter)) &&
//             (subject_filter == '' || subject.contains(subject_filter)) &&
//             (message_filter == '' || message.contains(message_filter))
//     } or {
//         return ctx.not_found()
//     }

//     // Return the filtered logs or a message if no logs match the criteria
//     if logs.len == 0 {
//         return ctx.text('No logs found matching the criteria')
//     }

//     return ctx.json(logs)
// }
