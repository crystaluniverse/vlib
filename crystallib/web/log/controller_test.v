module log

import json
import vweb
import db.sqlite
import time
import net.http

// const port = 8080
// const url = 'http://localhost:${port}'

// fn testsuite_begin() {
// 	mut db := sqlite.connect('test.sqlite')!
// 	sql db {
// 		create table Log
// 	} or { panic(err) }
// 	ctrl := &Controller{
// 		db: db
// 	}
// 	spawn vweb.run(ctrl, 8080)
// }

// fn test_log() {
// 	log := Log{
// 		subject: 'test_user'
// 		object: 'test_asset'
// 		event: 'access'
// 		timestamp: time.now()
// 	}
// 	data := json.encode(log)
// 	req := http.new_request(.post, '${analytics.url}/log', data)
// 	resp := req.do()!
// 	assert resp.status_code == 200
// }
