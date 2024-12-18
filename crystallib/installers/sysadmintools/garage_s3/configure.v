module garage_s3

import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.sysadmin.startupmanager
import freeflowuniverse.crystallib.crypt.secrets
// import freeflowuniverse.crystallib.core.texttools
// import freeflowuniverse.crystallib.clients.httpconnection
import os
import time

@[params]
pub struct S3Config {
pub mut:
	replication_mode    string = '3'
	metadata_dir        string = '/var/garage/meta'
	data_dir            string = '/var/garage/data'
	sled_cache_capacity u32    = 128 // in MB
	compression_level   u8     = 1

	rpc_secret        string //{GARAGE_RPCSECRET}
	rpc_bind_addr     string = '[::]:3901'
	rpc_bind_outgoing bool
	rpc_public_addr   string = '127.0.0.1:3901'

	bootstrap_peers []string

	api_bind_addr string = '[::]:3900'
	s3_region     string = 'garage'
	root_domain   string = '.s3.garage'

	web_bind_addr   string = '[::]:3902'
	web_root_domain string = '.web.garage'

	admin_api_bind_addr string = '[::]:3903'
	admin_metrics_token string //{GARAGE_METRICSTOKEN}
	admin_token         string //{GARAGE_ADMINTOKEN}
	admin_trace_sink    string = 'http://localhost:4317'

	reset        bool
	config_reset bool
	start        bool = true
	restart      bool = true
}

pub fn configure(args_ S3Config) !S3Config {
	mut args := args_

	if args.rpc_secret == '' {
		args.rpc_secret = secrets.openssl_hex_secret()!
		println('export GARAGE_RPCSECRET=${args.rpc_secret}')
	}

	if args.admin_metrics_token == '' {
		args.admin_metrics_token = secrets.openssl_base64_secret()!
		println('export GARAGE_METRICSTOKEN=${args.admin_metrics_token}')
	}

	if args.admin_token == '' {
		args.admin_token = secrets.openssl_base64_secret()!
		println('export GARAGE_ADMINTOKEN=${args.admin_token}')
	}

	mut config_file := $tmpl('templates/garage.toml')

	myconfigpath_ := '/etc/garage.toml'
	mut myconfigpath := pathlib.get_file(path: myconfigpath_, create: true)!
	myconfigpath.write(config_file)!

	console.print_header('garage start')

	return args
}

pub fn start(args_ S3Config) !S3Config {
	mut args := args_

	myconfigpath_ := '/etc/garage.toml'

	if args.config_reset || !os.exists(myconfigpath_) {
		args = configure(args)!
	}

	if args.restart {
		stop()!
	}

	mut sm := startupmanager.get()!

	sm.new(
		name:  'garage'
		cmd:   'garage -c ${myconfigpath_} server'
		start: true
	)!

	console.print_debug('garage -c ${myconfigpath_} server')

	for _ in 0 .. 50 {
		if check(args)! {
			return args
		}
		time.sleep(100 * time.millisecond)
	}

	return error('garage server did not start properly.')
}

pub fn stop() ! {
	console.print_header('garage stop')
	mut sm := startupmanager.get()!
	sm.stop('garage')!
}

fn check(args S3Config) !bool {
	cmd := 'garage status'
	res := os.execute('garage status')
	if res.exit_code == 0 {
		return true
	}
	return false
}
