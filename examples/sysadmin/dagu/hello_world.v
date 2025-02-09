module main

import freeflowuniverse.crystallib.sysadmin.dagu

fn main() {
	do() or { panic(err) }
}

fn do() ! {
	mut d := dagu.new()!
	d.new_dag(
		name:  'hello world'
		steps: [
			dagu.Step{
				name:    's1'
				command: 'echo hello world'
			},
			dagu.Step{
				name:    's2'
				command: 'echo done'
				depends: 's1'
			},
		]
	)
	// dagu.server()!
	println(d.start('hello world')!)
	d.delete('hello world')!
}
