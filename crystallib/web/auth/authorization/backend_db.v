module authorization

// import rand
// import db.sqlite
// import time
// import log

// @[noinit]
// pub struct DBBackend {
// mut:
// 	db sqlite.DB
// }

// // factory for
// pub fn new_backend(config DBBackendConfig) !DBBackend {
// 	// db := sqlite.connect(config.db_path) or { panic(err) }

// 	// sql db {
// 	// 	create table User
// 	// } or { panic(err) }

// 	return DBBackend{
// 		// logger: config.logger
// 		// db: db
// 	}
// }

// fn (mut backend DBBackend) create_user(email string) User {
// 	user := User{
// 		id: rand.uuid_v4()
// 		email: email
// 	}

// 	// sql backend.db {
// 	// 	insert user into User
// 	// } or { panic('Error insterting user ${user} into identity database:${err}') }

// 	return user
// }

// pub struct ReadUserParams {
// 	id    string
// 	email string
// }

// fn (mut backend DBBackend) read_user(params ReadUserParams) ?User {
// 	mut user := []User{}
// 	if params.id != '' {
// 		user = sql backend.db {
// 			select from User where id == '${params.id}'
// 		} or { panic('err:${err}') }
// 	} else if params.email != '' {
// 		user = sql backend.db {
// 			select from User where email == '${params.email}'
// 		} or { panic('err:${err}') }
// 	} else {
// 		return none
// 	}
// 	return user[0] or { return none }
// 	return none
// }

// fn (mut backend DBBackend) read_users() ![]User {
// 	// users := sql backend.db {
// 	// 	select from User
// 	// }!
// 	// return users
// 	return []User{}
// }
