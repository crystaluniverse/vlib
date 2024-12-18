module mailclient

import freeflowuniverse.crystallib.data.paramsparser
import os

pub const version = '1.0.0'
const singleton = false
const default = true

// TODO: THIS IS EXAMPLE CODE AND NEEDS TO BE CHANGED IN LINE TO STRUCT BELOW, IS STRUCTURED AS HEROSCRIPT
pub fn heroscript_default() string {
	mail_from := os.getenv_opt('MAIL_FROM') or { 'info@example.com' }
	mail_password := os.getenv_opt('MAIL_PASSWORD') or { 'secretpassword' }
	mail_port := (os.getenv_opt('MAIL_PORT') or { '465' }).int()
	mail_server := os.getenv_opt('MAIL_SERVER') or { 'smtp-relay.brevo.com' }
	mail_username := os.getenv_opt('MAIL_USERNAME') or { 'kristof@incubaid.com' }

	heroscript := "
!!mailclient.configure name:'default'
    mail_from: '${mail_from}'
    mail_password: '${mail_password}'
    mail_port: ${mail_port}
    mail_server: '${mail_server}'
    mail_username: '${mail_username}'  
"

	return heroscript
}

pub struct MailClient {
pub mut:
	name          string = 'default'
	mail_from     string
	mail_password string @[secret]
	mail_port     int = 465
	mail_server   string
	mail_username string
	ssl           bool = true
	tls           bool
}

fn cfg_play(p paramsparser.Params) ! {
	mut mycfg := MailClient{
		name:          p.get_default('name', 'default')!
		mail_from:     p.get('mail_from')!
		mail_password: p.get('mail_password')!
		mail_port:     p.get_int_default('mail_port', 465)!
		mail_server:   p.get('mail_server')!
		mail_username: p.get('mail_username')!
	}
	set(mycfg)!
}

fn obj_init(obj_ MailClient) !MailClient {
	// never call get here, only thing we can do here is work on object itself
	mut obj := obj_
	return obj
}

// user needs to us switch to make sure we get the right object
pub fn configure(config MailClient) !MailClient {
	client := MailClient{
		...config
	}
	set(client)!
	return client
	// THIS IS EXAMPLE CODE AND NEEDS TO BE CHANGED

	// implement if steps need to be done for configuration
}
