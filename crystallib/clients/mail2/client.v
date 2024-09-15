module mail

import freeflowuniverse.crystallib.core.base
import freeflowuniverse.crystallib.core.texttools
import net.smtp
import time

pub fn (mut self MailClient[Config]) set_smtp_client() ! {
	cfg := self.config()!
	if self.smtp_client.server != cfg.smtp_addr || self.smtp_client.port != cfg.smtp_port
		|| self.smtp_client.username != cfg.smtp_login
		|| self.smtp_client.password != cfg.smtp_passwd {
		mut smtp_client := smtp.new_client(
			server: cfg.smtp_addr
			port: cfg.smtp_port
			username: cfg.smtp_login
			password: cfg.smtp_passwd
			from: cfg.mail_from
			ssl: cfg.ssl
			starttls: cfg.starttls
		)!
		self.smtp_client = smtp_client
	}
}

@[params]
pub struct SendArgs {
pub mut:
	markdown  bool
	from      string
	to        string
	cc        string
	bcc       string
	date      time.Time = time.now()
	subject   string
	body_type BodyType
	body      string
}

enum BodyType {
	text
	html
	markdown
}

// ```
// cl.send(markdown:true,subject:'this is a test',to:'kds@something.com,kds2@else.com',content:'
//     this is my email content
//     ')
// args:
// 	markdown  bool
// 	from      string
// 	to        string
// 	cc        string
// 	bcc       string
// 	date      time.Time = time.now()
// 	subject   string
// 	body_type BodyType (.html, .text, .markdown)
// 	body      string
// ```
pub fn (mut cl MailClient[Config]) send(args_ SendArgs) ! {
	mut args := args_
	args.body = texttools.dedent(args.body)
	mut body_type := smtp.BodyType.text
	if args.body_type == .html || args.body_type == .markdown {
		body_type = smtp.BodyType.html
	}
	mut m := smtp.Mail{
		from: args.from
		to: args.to
		cc: args.cc
		bcc: args.bcc
		date: args.date
		subject: args.subject
		body: args.body
		body_type: body_type
	}
	cl.set_smtp_client()!
	return cl.smtp_client.send(m)
}
