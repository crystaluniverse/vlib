module livekit

import freeflowuniverse.crystallib.data.paramsparser
import os

pub const version = '1.7.2'
const singleton = false
const default = true

// TODO: THIS IS EXAMPLE CODE AND NEEDS TO BE CHANGED IN LINE TO STRUCT BELOW, IS STRUCTURED AS HEROSCRIPT
pub fn heroscript_default() !string {
	heroscript := "
    !!livekit.configure 
        name:'default'
        apikey: ''
        apisecret: ''
        nr: 1 // each specific instance onto this server needs to have a unique nr
        "

	return heroscript
}

// THIS THE THE SOURCE OF THE INFORMATION OF THIS FILE, HERE WE HAVE THE CONFIG OBJECT CONFIGURED AND MODELLED

pub struct LivekitServer {
pub mut:
	name       string = 'default'
	apikey     string
	apisecret  string @[secret]
	configpath string
	nr         int = 0 // each specific instance onto this server needs to have a unique nr
}

fn cfg_play(p paramsparser.Params) !LivekitServer {
	mut mycfg := LivekitServer{
		name:      p.get_default('name', 'default')!
		apikey:    p.get_default('apikey', '')!
		apisecret: p.get_default('apisecret', '')!
		nr:        p.get_default_int('nr', 0)!
	}
	return mycfg
}

fn obj_init(obj_ LivekitServer) !LivekitServer {
	mut mycfg := obj_
	if mycfg.configpath == '' {
		mycfg.configpath = '${os.home_dir()}/hero/cfg/livekit_${myconfig.name}.yaml'
	}
	if mycfg.apikey == '' || mycfg.apisecret == '' {
		// Execute the livekit-server generate-keys command
		result := os.execute('livekit-server generate-keys')
		if result.exit_code != 0 {
			return error('Failed to generate LiveKit keys')
		}
		// Split the output into lines
		lines := result.output.split_into_lines()

		// Extract API Key and API Secret
		for line in lines {
			if line.starts_with('API Key:') {
				server.apikey = line.all_after('API Key:').trim_space()
			} else if line.starts_with('API Secret:') {
				server.apisecret = line.all_after('API Secret:').trim_space()
			}
		}
		// Verify that both keys were extracted
		if server.apikey == '' || server.apisecret == '' {
			return error('Failed to extract API Key or API Secret')
		}
	}
	return obj
}

// called before start if done
fn configure() ! {
	mut installer := get()!

	mut mycode := $tmpl('templates/config.yaml')
	mut path := pathlib.get_file(path: installer.configpath, create: true)!
	path.write(mycode)!
	console.print_debug(mycode)
}
