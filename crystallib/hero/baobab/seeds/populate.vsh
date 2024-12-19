#!/usr/bin/env -S  v -n -cg -w -enable-globals run

import freeflowuniverse.crystallib.baobab.generator
import freeflowuniverse.crystallib.core.codemodel { Struct }
import freeflowuniverse.crystallib.core.codeparser
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.ui.console
import os

const actors_dir = '${os.dir(os.dir(@FILE))}/actors'

// a map of each actor with the base objects they are responsible of
const actor_object_map = {
	'accountant':  ['Budget']
	'coordinator': ['Story']
	'scheduler':   ['Calendar', 'Event']
}

mut seed_dir := pathlib.get_dir(path: os.dir(@FILE))!
mut dir_list := seed_dir.list()!

code := codeparser.parse_v(seed_dir.path, recursive: true)!
structs := code.filter(it is Struct).map(it as Struct)

for name, objects in actor_object_map {
	actor_objects := structs.filter(it.name in objects)
	mut actor := generator.generate_actor(name, actor_objects) or {
		console.print_debug('Failed to generate actor ${name}\n${err}')
		continue
	}

	actor_module := actor.generate_module() or {
		onsole.print_debug('Failed to generate actor module ${name}\n${err}')
		continue
	}

	actor_module.write_v('${actors_dir}', format: true, overwrite: true) or {
		console.print_debug('Failed to generate actor ${name}\n${err}')
		continue
	}

	// playground := actor.generate_playground() or {
	// 	console.print_debug('Failed to generate actor module ${name}\n${err}')
	// 	continue
	// }
	actor.export_playground('${actors_dir}/${name}', '${actors_dir}/${name}/openrpc.json')!
	actor.export_command('${actors_dir}/${name}')!

	// openrpc_path := '${actors_dir}/${name}/openrpc'
	// openrpc_module.write_v(openrpc_path, format: true, document: true)!
}
