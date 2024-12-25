module meilisearchserver_module
import freeflowuniverse.crystallib.data.paramsparser
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.playbook
import os

pub fn heroscript_default() !string {
    heroscript:="
        !!meilisearchserver.configure
            name: 'myname'
            path: '/var/lib/meilisearch'
            masterkey: 'supersecretkey'
            host: 'localhost'
            port: 7700
            production: 1

        !!meilisearchserver.start
            name: 'myname'
            reset: 1 
    "
    return heroscript
}

@[heap]
pub struct MeilisearchServer {
pub mut:
	name       string = 'default'
	path       string
	masterkey  string @[secret]
	host       string
	port       int
	production bool
}

@[params]
pub struct StartArgs {
pub mut:
	name       string = 'default'
	reset bool
}

pub fn play_meilisearchserver(mut plbook playbook.PlayBook) ! {
	actions := plbook.find(filter: 'meilisearchserver.')!
	for action in actions {
		if action.name_ == "configure" {
			mut p := action.params
			mut obj := MeilisearchServer{
				name: p.get_default('name', 'default')!,
				path: p.get('path')!,
				masterkey: p.get('masterkey')!,
				host: p.get('host')!,
				port: p.get_int('port')!,
				production: p.get_default_false('production'),
			}
			//console.print_debug(obj)
		} else if action.name_ == "start" {
			mut p := action.params
			mut obj := StartArgs{
				name: p.get_default('name', 'default')!,
				reset: p.get_default_false('reset'),
			}
			//console.print_debug(obj)
		}
	}
}
