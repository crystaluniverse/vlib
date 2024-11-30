module log

import vweb
import db.sqlite
import json

// pub struct Controller {
// 	vweb.Context
// pub mut:
// 	db sqlite.DB
// }

// @[post]
// pub fn (mut ctrl Controller) log() vweb.Result {
// 	log := json.decode(Log, ctrl.req.data) or {
// 		ctrl.set_status(400, '')
// 		return ctrl.text('Failed to decode request data.')
// 	}
// 	sql ctrl.db {
// 		insert log into Log
// 	} or {
// 		ctrl.set_status(500, '')
// 		return ctrl.text('Failed insert log into db.')
// 	}
// 	return ctrl.ok('')
// }

// @[get]
// pub fn (mut ctrl Controller) logs() vweb.Result {
// 	logs := sql ctrl.db {
// 		select from Log
// 	} or {
// 		ctrl.set_status(500, '')
// 		return ctrl.text('Failed insert log into db.')
// 	}
// 	return ctrl.json(logs)
// }
