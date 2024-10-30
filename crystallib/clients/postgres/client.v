module postgres

import freeflowuniverse.crystallib.core.base
import db.pg
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.ui.console

// pub struct PostgresClient {
// 	base.BaseConfig
// pub mut:
// 	config Config
// 	db     pg.DB
// }

// @[params]
// pub struct ClientArgs {
// pub mut:
// 	instance string         @[required]
// 	// playargs ?play.PlayArgs
// }

// pub fn get(clientargs ClientArgs) !PostgresClient {
// 	// mut plargs := clientargs.playargs or {
// 	// 	// play.PlayArgs
// 	// 	// {
// 	// 	// }
// 	// }

// 	// mut cfg := configurator(clientargs.instance, plargs)!
// 	// mut args := cfg.get()!

// 	args.instance = texttools.name_fix(args.instance)
// 	if args.instance == '' {
// 		args.instance = 'default'
// 	}
// 	// console.print_debug(args)
// 	mut db := pg.connect(
// 		host: args.host
// 		user: args.user
// 		port: args.port
// 		password: args.password
// 		dbname: args.dbname
// 	)!
// 	// console.print_debug(postgres_client)
// 	return PostgresClient{
// 		instance: args.instance
// 		db: db
// 		config: args
// 	}
// }

struct LocalConfig {
	name   string
	path   string
	passwd string
}
