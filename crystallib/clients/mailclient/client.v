module mailclient

import freeflowuniverse.crystallib.core.texttools
import net.smtp
import time

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

pub enum BodyType {
	text
	html
	markdown
}

// ```
// cl.send(markdown:true,subject:'this is a test',to:'kds@something.com,kds2@else.com',body:'
//     this is my email content
//     ')!
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
pub fn (mut cl MailClient) send(args_ SendArgs) ! {
	mut args := args_
	args.body = texttools.dedent(args.body)
	mut body_type := smtp.BodyType.text
	if args.body_type == .html || args.body_type == .markdown {
		body_type = smtp.BodyType.html
	}
	mut m := smtp.Mail{
		from:      args.from
		to:        args.to
		cc:        args.cc
		bcc:       args.bcc
		date:      args.date
		subject:   args.subject
		body:      args.body
		body_type: body_type
	}

	mut smtp_client := smtp.new_client(
		server:   cl.mail_server
		port:     cl.mail_port
		username: cl.mail_username
		password: cl.mail_password
		from:     cl.mail_from
		ssl:      cl.ssl
		starttls: cl.tls
	)!

	return smtp_client.send(m)
}
