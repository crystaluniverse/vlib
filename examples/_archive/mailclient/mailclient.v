module main

import freeflowuniverse.crystallib.clients.mail

fn foo() ! {
	mut cl := mail.configurator('first2')!
	cl.set(mail.config(smtp_addr: 'myserver'))!
	c := cl.get()!
	println(c)
	assert c.smtp_addr == 'myserver'

	c2 := cl.getset(mail.config(smtp_addr: 'myserver2'))!
	assert c2.smtp_addr == 'myserver'
}

fn main() {
	foo() or { panic(err) }
}
