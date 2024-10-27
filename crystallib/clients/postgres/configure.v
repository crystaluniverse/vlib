module postgres

import freeflowuniverse.crystallib.core.base
import freeflowuniverse.crystallib.ui
import freeflowuniverse.crystallib.ui.console

@[params]
pub struct Config {
pub mut:
	instance   string = 'default'
	user       string = 'root'
	port       int    = 5432
	host       string = 'localhost'
	password   string
	dbname     string = 'postgres'
	heroscript string
	reset      bool
}

pub fn configure(instance string, cfg_ Config) !PostgresClient[Config] {
	mut config := cfg_

	mut server := PostgresClient[Config] {}
	server.init('postgres', instance, .set, config)!
	return get(instance)!
}

pub fn configure_interactive(args_ Config, mut session base.Session) ! {
	mut args := args_
	mut myui := ui.new()!

	console.clear()
	console.print_debug('\n## Configure Postgres Client')
	console.print_debug('============================\n\n')

	instance := myui.ask_question(
		question: 'name for postgres client'
		default: args.instance
	)!

	args.user = myui.ask_question(
		question: 'user'
		minlen: 3
		default: args.user
	)!

	args.password = myui.ask_question(
		question: 'password'
		minlen: 3
		default: args.password
	)!

	args.dbname = myui.ask_question(
		question: 'dbname'
		minlen: 3
		default: args.dbname
	)!

	args.host = myui.ask_question(
		question: 'host'
		minlen: 3
		default: args.host
	)!
	mut port := myui.ask_question(
		question: 'port'
		default: '${args.port}'
	)!
	args.port = port.int()

	mut client := PostgresClient[Config]{}
	client.init('postgres', instance, .set, args)!
}

// pub fn play_session(mut session base.Session) ! {
// 	for mut action in session.plbook.find(filter: 'postgresclient.define')! {
// 		mut p := action.params
// 		mut args := config()
// 		panic('implement')
// 		// args.instance = p.get_default('name','')!
// 		// if args.instance == ""{
// 		// 	args.instance = p.get_default('instance', 'default')!
// 		// }				
// 		// args.mail_from = p.get('mail_from')!
// 		// args.smtp_addr = p.get('smtp_addr')!
// 		// args.smtp_login = p.get('smtp_login')!
// 		// args.smtp_passwd = p.get('smtp_passwd')!
// 		// args.smpt_port = p.get_int('smpt_port')!		
// 		// mut c:=configurator(args.instance,session:session)!
// 		// c.set(args)!
// 	}
// }