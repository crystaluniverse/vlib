module peertube

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.core.texttools
import json
import freeflowuniverse.crystallib.data.dbfs
// import freeflowuniverse.crystallib.develop.gittools
import os
import freeflowuniverse.crystallib.ui.console

@[params]
pub struct Config {
pub mut:
	name   string = 'default'
	dest   string = '/data/peertube'
	passwd string
	reset  bool

	mailclient_name string = 'default'

	postgresql_name string = 'default'
}

fn configure_init(reset bool, mut args Config) ! {
	args.name = texttools.name_fix(args.name)

	key := 'peertube_config_${args.name}'
	mut kvs := dbfs.new(name: 'config')!
	if reset || !kvs.exists(key) {
		data := json.encode_pretty(args)
		kvs.set(key, data)!
	}
	data := kvs.get(key)!
	args = json.decode(Config, data)!

	dest := args.dest
	// if !(os.exists("${dest}")){
	//     return error("can't find dest: ${dest}")
	// }

	// pathlib.template_write($tmpl("templates/Dockerfile"),
	//                               "${dest}/Dockerfile",reset)!
	// pathlib.template_write($tmpl("templates/entrypoint.sh"),
	//                               "${dest}/entrypoint.sh",reset)!

	$if debug {
		console.print_header('peertube configured properly.')
	}
}
