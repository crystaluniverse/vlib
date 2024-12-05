module email

import log
import net.smtp
import os
import toml

fn test_new_controller() {
	mut logger := log.Logger(&log.Log{
		level: .debug
	})

	env := toml.parse_file(os.dir(os.dir(@FILE)) + '/.env') or {
		panic('Could not find .env, ${err}')
	}

	client := smtp.Client{
		server: 'smtp-relay.brevo.com'
		from: 'verify@authenticator.io'
		port: 587
		username: env.value('BREVO_SMTP_USERNAME').string()
		password: env.value('BREVO_SMTP_PASSWORD').string()
	}

	controller := new_controller(logger: &logger)
}

fn test_send_verification_mail() {
	// mut logger := log.Logger(&log.Log{
	// 	level: .debug
	// })

	// env := toml.parse_file(os.dir(os.dir(@FILE)) + '/.env') or {
	// 	panic('Could not find .env, ${err}')
	// }

	// client := smtp.Client{
	// 	server: 'smtp-relay.brevo.com'
	// 	from: 'verify@authenticator.io'
	// 	port: 587
	// 	username: env.value('BREVO_SMTP_USERNAME').string()
	// 	password: env.value('BREVO_SMTP_PASSWORD').string()
	// }

	// controller := new_controller(logger: &logger)
}
