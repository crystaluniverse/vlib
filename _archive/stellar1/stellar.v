module stellar

import freeflowuniverse.crystallib.lang.python
import json
import freeflowuniverse.crystallib.ui.console

pub struct Person {
	name      string
	age       int
	is_member bool
	skills    []string
}

@[params]
pub struct StellarGetArgs {
pub mut:
	instance string
	reset    bool
}

pub fn new(args StellarGetArgs) {
	mut cl := get(instance: args.instance)!

	if args.reset {
		cl.config_delete()!
	}

	mut cfg := cl.config()!
	if cfg.secret == '' {
		// will ask questions if not filled in yet
		cl.config_interactive()!
	}
	console.print_debug('${cfg}')
}

mut py := python.new(name: 'main')! // a python env with name test
py.update()!
py.pip('stellar-sdk')!

cmd := $tmpl('stellar.py')
// for i in 0..100{
// 	console.print_debug(i)
// 	res:=py.exec(cmd:cmd)!
// }
res := py.exec(cmd: cmd)!

person := json.decode(Person, res)!
console.print_debug(person)
