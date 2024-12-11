module authorization

import vweb
import db.sqlite
import rand
import json
import freeflowuniverse.crystallib.ui.console

pub struct Controller {
	vweb.Context
pub mut:
	db sqlite.DB
}

pub fn (mut ctrl Controller) before_request() {
	console.print_debug(ctrl.req)
}

// [post]
// pub fn (mut ctrl Controller) register() vweb.Result {

// 	user := User{
// 		...user_
// 		id: rand.uuid_v4()
// 	}

// 	sql ctrl.db {
// 		insert user into User
// 	} or {
// 		ctrl.set_status(500, '')
// 		return ctrl.text('Failed insert user ${user} into db.')
// 	}

// 	return ctrl.text(user.id)
// }
