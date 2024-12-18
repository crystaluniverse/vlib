module threebot

import log
import freeflowuniverse.threebot.mail
import freeflowuniverse.crystallib.data.rpcwebsocket

pub struct Threebot {
	mail mail.Mail
}

pub fn (bot Threebot) run() ! {
	mut logger := log.Logger(&log.Log{
		level: .debug
	})

	mail_handler := mail.new_handler(
		logger:       &logger
		state:        &bot.mail
		openrpc_path: '.'
	)!

	mut jsonrpc_ws_server := rpcwebsocket.new_rpcwsserver(8080, mail_handler, &logger)!
	jsonrpc_ws_server.run()!
}

// > TODO: what is this????
