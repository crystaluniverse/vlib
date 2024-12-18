#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.clients.mail

mut cl := mail.get(instance: 'ashrafmail')!

mut cfg := cl.config()!
cfg.mail_from = 'ashraf@example.com'
cfg.smtp_addr = 'smtp.sendgrid.net'
cfg.smtp_login = 'apikey'
cfg.smtp_port = 587
cfg.smtp_passwd = 'password'
cfg.ssl = false
cfg.starttls = true
cl.config_save()!

if cfg.smtp_passwd == '' {
	cl.config_interactive()!
}

cl.send(from: 'ashraf@example.com', to: 'ashraf.m.fouda@example.com', subject: 'test')!
println(cfg)
