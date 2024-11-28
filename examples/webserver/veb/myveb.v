module main

import veb
import os
import freeflowuniverse.crystallib.web.heroweb
import freeflowuniverse.crystallib.security.authentication
import freeflowuniverse.crystallib.clients.mailclient
import freeflowuniverse.crystallib.osal


pub struct Context {
	veb.Context
pub mut:
	// In the context struct we store data that could be different
	// for each request. Like a User struct or a session id
	user_id string
}


//  mut db := Authorizer{}

//     db.user_add(name: 'john', email: 'john@example.com') or { panic(err) }
//     db.group_add(name: 'admins', user_names: ['john']) or { panic(err) }
//     db.acl_add(name: 'default', entries: [ACE{group: 'admins', right: .admin}]) or { panic(err) }
//     db.infopointer_add(name: 'test', path: '/test', acl: ['default']) or { panic(err) }
//     db.infopointer_resolve('test') or { panic(err) }

//     println(db)

pub fn main()  {
	osal.load_env_file('${os.dir(@FILE)}/.env')!
	mail_client := mailclient.configure(
		name: 'myweb',
		mail_from: 'myweb@info.tf'
		mail_username: os.getenv('BREVO_SMTP_USERNAME')
		mail_password: os.getenv('BREVO_SMTP_PASSWORD')
		mail_port: 465
		mail_server: 'smtp-relay.brevo.com'

	) or {panic(err)}

	mut app := heroweb.new(
		authenticator: authentication.new(
			mail_client: mail_client
		)!
	)!
	veb.run[heroweb.App, Context](mut app, 8090)
}
