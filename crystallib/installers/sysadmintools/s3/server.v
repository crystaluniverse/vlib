module s3

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.osal.zinit
import freeflowuniverse.crystallib.data.dbfs
import freeflowuniverse.crystallib.core.texttools
import json
import rand
import freeflowuniverse.crystallib.ui.console

// --fs-root <fs-root>             [default: .]
// --host <host>                   [default: localhost]
// --meta-root <meta-root>         [default: .]
// --metric-host <metric-host>     [default: localhost]
// --metric-port <metric-port>     [default: 9100]
// --port <port>                   [default: 8014]
// --access-key <access-key>
// --secret-key <secret-key>
@[params]
pub struct Config {
pub mut:
	name        string = 'default'
	fs_root     string = '/var/data/s3'
	host        string = 'localhost'
	meta_root   string = '/var/data/s3_meta'
	metric_host string = 'localhost'
	metric_port int    = 9100
	port        int    = 8014
	access_key  string
	secret_key  string
}

pub struct Server {
pub mut:
	name    string
	config  Config
	process ?zinit.ZProcess
}

// get the s3 server
//```js
// fs_root string = "/var/data/s3"
// host string = "localhost"
// meta_root string = "/var/data/s3_meta"
// metric_host string
// metric_port int //9100
// port int = 8014
// access_key string @[required]
// secret_key string
//```
// if name exists already in the config DB, it will load for that name
pub fn new(args_ Config) !Server {
	install()! // make sure it has been build & ready to be used
	mut args := args_
	args.name = texttools.name_fix(args.name)
	key := 's3_config_${args.name}'
	mut kvs := dbfs.new(name: 'config')!
	if !kvs.exists(key) {
		if args.access_key == '' {
			args.access_key = rand.string(12)
		}
		if args.secret_key == '' {
			args.secret_key = rand.string(12)
		}
		data := json.encode(args)
		console.print_debug('set config s3')
		kvs.set(key, data)!
	}
	return get(args.name)!
}

pub fn get(name_ string) !Server {
	name := texttools.name_fix(name_)
	key := 's3_config_${name}'
	mut kvs := dbfs.new(name: 'config')!
	if kvs.exists(key) {
		data := kvs.get(key)!
		args := json.decode(Config, data)!
		mut server := Server{
			name: name
			config: args
		}
		mut z := zinit.new()!
		processname := 's3_${args.name}'
		if z.process_exists(processname) {
			server.process = z.process_get(processname)!
		}
		return server
	}
	return error("can't find S3 server with name:'${name}'")
}

pub fn (mut server Server) start() ! {
	mut args := server.config

	mut cmd := 's3-cas --fs-root ${args.fs_root} --host ${args.host} --meta-root ${args.meta_root} --port ${args.port}'
	if args.metric_host.len > 0 {
		cmd += ' --metric-host ${args.metric_host}'
	}
	if args.metric_port > 0 {
		cmd += ' --metric-port ${args.metric_port}'
	}
	if args.secret_key == '' {
		args.secret_key = args.access_key
	}
	cmd += ' --access-key ${args.access_key}'
	cmd += ' --secret-key ${args.secret_key}'

	mut z := zinit.new()!
	mut p := z.process_new(
		name: 's3_${args.name}'
		cmd: cmd
	)!

	p.status()!
	p.output_wait('server is running at', 10)!
}

// return status
// ```
// pub enum ZProcessStatus {
// 	unknown
// 	init
// 	ok
// 	error
// 	blocked
// 	spawned
// }
// ```
pub fn (mut server Server) status() !zinit.ZProcessStatus {
	mut process := server.process or { return error("can't find process yet.") }
	return process.status()!
}

// will check if running
pub fn (mut server Server) check() ! {
	mut process := server.process or { return error("can't find process yet.") }
	process.check()!
	// TODO: need to do more checks S3 checks
}

pub fn (mut server Server) stop() ! {
	mut process := server.process or { return error("can't find process yet.") }
	return process.stop()
}
