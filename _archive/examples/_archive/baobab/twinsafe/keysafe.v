module main

import freeflowuniverse.crystallib.baobab.twinsafe

fn do() ! {
	data := "
		this is some text
		don't wanna make it too small
		lets see where this brings us
	"

	// TODO: create some messages and see it all works properly
	ksargs := twinsafe.KeysSafeNewArgs{
		path:   '/tmp/twinsafe'
		secret: 'testsec'
	}
	mut ks := twinsafe.new(ksargs)!
	twinsafe.create_tables(ks.db)!
	ks.myconfig_add(name: 'myconfig1', description: 'mydescription', config: 'someconfig') or {
		println('${err}')
	}

	myconfig := ks.myconfig_get(twinsafe.GetArgs{ name: 'myconfig1', id: 0 })!
	println(myconfig.config)

	ks.mytwin_add(
		name:        'mytwin1'
		description: 'mytwin description'
		privkey:     '0x8225825815f42e1c24a2e98714d99fee1a20b5ac864fbcb7a103cd0f37f0ffec'
	) or { println('${err}') }
	mytwin := ks.mytwin_get(twinsafe.GetArgs{ name: 'mytwin1', id: 0 })!
	println('privkey for twin1 ${mytwin.privkey.export()}')

	ks.mytwin_add(name: 'mytwin2', description: 'mytwin description') or { println('${err}') }
	mytwin2 := ks.mytwin_get(twinsafe.GetArgs{ name: 'mytwin2', id: 0 })!
	println('privkey for twin2 ${mytwin2.privkey.export()}')

	ks.othertwin_add(
		name:        'othertwin1'
		description: 'othertwin description'
		conn_type:   twinsafe.TwinConnectionType.ipv4
		addr:        '127.0.0.1'
		pubkey:      '0x8225825815f42e1c24a2e98714d99fee1a20b5ac864'
	) or { println('${err}') }
	otwin := ks.othertwin_get(twinsafe.GetArgs{ name: 'othertwin1', id: 0 })!
	println(otwin.description)
}

fn main() {
	do() or { panic(err) }
}
