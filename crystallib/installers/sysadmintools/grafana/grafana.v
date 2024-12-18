module grafana

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.clients.httpconnection
import freeflowuniverse.crystallib.sysadmin.startupmanager
import os
import time

@[params]
pub struct InstallArgs {
pub mut:
	// homedir    string
	// configpath string
	// username   string = "admin"
	// password   string @[secret]
	// secret     string @[secret]
	// title      string = 'My Hero DAG'
	reset     bool
	start     bool = true
	stop      bool
	restart   bool
	uninstall bool
	// host        string = 'localhost' // server host (default is localhost)
	// port       int = 8888
}

pub fn install(args_ InstallArgs) ! {
	mut args := args_

	version := '11.1.4'

	res := os.execute('${osal.profile_path_source_and()} grafana --version')
	if res.exit_code == 0 {
		r := res.output.split_into_lines().filter(it.trim_space().starts_with('grafana'))
		if r.len != 1 {
			args.reset = true
		}
		version2 := r[0].split('version')[1]
		if texttools.version(version) > texttools.version(version2) {
			args.reset = true
		}
	} else {
		args.reset = true
	}

	if args.reset {
		console.print_header('install grafana')

		mut url := ''
		if osal.is_linux_intel() {
			url = 'https://dl.grafana.com/oss/release/grafana-${version}.linux-amd64.tar.gz'
		} else {
			return error('unsuported platform, only linux amd64 for now')
		}

		mut dest := osal.download(
			url:        url
			minsize_kb: 15000
			expand_dir: '/tmp/grafana'
		)!

		mut mypath := pathlib.get_dir(path: '/tmp/grafana/grafana-v${version}')!
		mypath.copy(dest: '/root/hero/grafana', delete: false, rsync: true)!

		osal.profile_path_add_remove(paths2add: '/root/hero/grafana/bin')!
	}

	// if args.restart {
	// 	restart(args)!
	// 	return
	// }

	// if args.start {
	// 	start(args)!
	// 	return
	// }

	// if args.stop {
	// 	stop()!
	// }	
}

// pub fn start(args_ InstallArgs) ! {
// 	mut args := args_

// 	if args.title == '' {
// 		args.title = 'HERO DAG'
// 	}

// 	if args.homedir == '' {
// 		args.homedir = '${os.home_dir()}/hero/var/grafana'
// 	}
// 	if args.configpath == '' {
// 		args.configpath = '${os.home_dir()}/hero/cfg/grafana.yaml'
// 	}

// 	if check(args)! {
// 		return
// 	}

// 	console.print_header('grafana start')

// 	//println(args)

// 	configure(args)!

// 	cmd := 'grafana server --host 0.0.0.0 --config ${args.configpath}'

// 	// TODO: we are not taking host & port into consideration

// 	// dags string // location of DAG files (default is /Users/<user>/.grafana/dags)
// 	// host string // server host (default is localhost)
// 	// port string // server port (default is 8080)
// 	// result := os.execute_opt('grafana start-all ${flags}')!

// 	mut sm := startupmanager.get()!

// 	sm.start(
// 		name: 'grafana'
// 		cmd: cmd
// 		env: {
// 			'HOME': '/root'
// 		}
// 	)!

// 	//cmd2 := 'grafana scheduler' // TODO: do we need this
// 	console.print_debug(cmd)

// 	// if true{
// 	// 	panic("sdsdsds grafana install")
// 	// }

// 	// time.sleep(100000000000)
// 	for _ in 0 .. 50 {
// 		if check(args)! {
// 			return
// 		}
// 		time.sleep(100 * time.millisecond)
// 	}
// 	return error('grafana did not install propertly, could not call api.')	

// }

// pub fn configure(args_ InstallArgs) ! {
// 	mut cfg := args_

// 	if cfg.password == "" || cfg.secret == ""{
// 		return error("password and secret needs to be filled in for grafana")
// 	}

// 	mut mycode := $tmpl('templates/admin.yaml')

// 	mut path := pathlib.get_file(path: cfg.configpath, create: true)!
// 	path.write(mycode)!

// 	console.print_debug(mycode)

// }

// pub fn check(args InstallArgs) !bool {
// 	// this checks health of grafana
// 	// curl http://localhost:3333/api/v1/s --oauth2-bearer 1234 works
// 	mut conn := httpconnection.new(name: 'grafana', url: 'http://127.0.0.1:${args.port}/api/v1/')!

// 	// console.print_debug("curl http://localhost:3333/api/v1/dags --oauth2-bearer ${secret}")
// 	if args.secret.len > 0 {
// 		conn.default_header.add(.authorization, 'Bearer ${args.secret}')
// 	}
// 	conn.default_header.add(.content_type, 'application/json')
// 	console.print_debug('check connection to grafana')
// 	r0 := conn.get(prefix: 'dags') or { return false }
// 	// if it gets here then is empty but server answers, the below might not work if no dags loaded

// 	// println(r0)
// 	// if true{panic("ssss")}
// 	// r := conn.get_json_dict(prefix: 'dags', debug: false) or {return false}
// 	// println(r)
// 	// dags := r['DAGs'] or { return false }
// 	// // console.print_debug(dags)
// 	console.print_debug('Dagu is answering.')
// 	return true
// }

// pub fn stop() ! {
// 	console.print_header('Dagu Stop')
// 	mut sm := startupmanager.get()!
// 	sm.stop('grafana')!
// }

// pub fn restart(args InstallArgs) ! {
// 	stop()!
// 	start(args)!
// }

// pub fn installargs(args InstallArgs) InstallArgs {
// 	return args	
// }
