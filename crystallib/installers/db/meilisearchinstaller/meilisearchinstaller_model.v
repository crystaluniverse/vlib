module meilisearchinstaller

import freeflowuniverse.crystallib.data.paramsparser

pub const version = '1.11.3'
const singleton = false
const default = true

pub fn heroscript_default() !string {
	heroscript := "
    !!meilisearch.configure 
        name:'default'
        masterkey: '1234'
        host: 'localhost'
        port: 7700
        production: 0
        "

	return heroscript
}

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED
pub struct MeilisearchServer {
pub mut:
	name       string = 'default'
	path       string
	masterkey  string @[secret]
	host       string
	port       int
	production bool
}

fn cfg_play(p paramsparser.Params) !MeilisearchServer {
	name := p.get_default('name', 'default')!
	mut mycfg := MeilisearchServer{
		name:       name
		path:       p.get_default('path', '{HOME}/hero/var/meilisearch/${name}')!
		host:       p.get_default('host', 'localhost')!
		masterkey:  p.get_default('masterkey', '1234')!
		port:       p.get_int_default('port', 7700)!
		production: p.get_default_false('production')
	}
	return mycfg
}

fn obj_init(obj_ MeilisearchServer) !MeilisearchServer {
	// never call get here, only thing we can do here is work on object itself
	mut obj := obj_
	return obj
}

// called before start if done
fn configure() ! {
	// mut installer := get()!
	// mut mycode := $tmpl('templates/atemplate.yaml')
	// mut path := pathlib.get_file(path: cfg.configpath, create: true)!
	// path.write(mycode)!
	// console.print_debug(mycode)
}
