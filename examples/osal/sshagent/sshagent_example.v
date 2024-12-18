module main

import freeflowuniverse.crystallib.osal.sshagent

fn do1() ! {
	mut agent := sshagent.new()!
	println(agent)
	k := agent.get(name: 'kds') or { panic('notgound') }
	println(k)

	mut k2 := agent.get(name: 'books') or { panic('notgound') }
	k2.load()!
	println(k2.agent)

	println(agent)

	k2.forget()!
	println(k2.agent)

	// println(agent)
}

fn main() {
	do1() or { panic(err) }
}
