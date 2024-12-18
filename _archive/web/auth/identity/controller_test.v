module identity

import json
import vweb
import db.sqlite
import time
import net.http

const port = 8080
const url = 'http://localhost:${port}'

fn testsuite_begin() {
	mut db := sqlite.connect('test.sqlite')!
	sql db {
		create table User
	} or { panic(err) }
	ctrl := &Controller{
		db: db
	}
	spawn vweb.run(ctrl, 8080)
}

fn test_register() {
	user := User{
		email: 'test@email.com'
	}
	data := json.encode(user)
	req := http.new_request(.post, '${url}/register', data)
	resp := req.do()!
	assert resp.status_code == 200
	assert resp.body.len > 0
}
