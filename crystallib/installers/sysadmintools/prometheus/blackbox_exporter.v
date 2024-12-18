module prometheus

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.clients.httpconnection
import freeflowuniverse.crystallib.sysadmin.startupmanager
import os
import time

pub fn install_blackbox_exporter(args_ InstallArgs) ! {
	mut args := args_

	version := '0.25.0'

	res := os.execute('${osal.profile_path_source_and()} blackbox_exporter --version')
	if res.exit_code == 0 {
		r := res.output.split_into_lines().filter(it.trim_space().starts_with('blackbox_exporter'))
		if r.len != 1 {
			args.reset = true
		}
		version2 := r[0].split('version')[1].split('(')[0]
		if texttools.version(version) > texttools.version(version2) {
			args.reset = true
		}
	} else {
		args.reset = true
	}

	if args.reset {
		console.print_header('install blackbox_exporter')

		mut url := ''
		if osal.is_linux_intel() {
			url = 'https://github.com/prometheus/blackbox_exporter/releases/download/v${version}/blackbox_exporter-${version}.linux-amd64.tar.gz'
		} else {
			return error('unsuported platform, only linux amd64 for now')
		}

		mut dest := osal.download(
			url:        url
			minsize_kb: 9000
			expand_dir: '/tmp/prometheus'
		)!

		mut dest2 := pathlib.get_dir(
			path: '/tmp/prometheus/blackbox_exporter-${version}.linux-amd64'
		)!
		for abin in ['blackbox_exporter'] {
			mut binpath := dest2.file_get(abin)!
			binpath.copy(dest: '/root/hero/prometheus/${abin}', delete: true, rsync: false)!
		}
		osal.profile_path_add_remove(paths2add: '/root/hero/prometheus')!
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
// 		args.homedir = '${os.home_dir()}/hero/var/prometheus'
// 	}
// 	if args.configpath == '' {
// 		args.configpath = '${os.home_dir()}/hero/cfg/prometheus.yaml'
// 	}

// 	if check(args)! {
// 		return
// 	}

// 	console.print_header('prometheus start')

// 	//println(args)

// 	configure(args)!

// 	cmd := 'prometheus server --host 0.0.0.0 --config ${args.configpath}'

// 	// TODO: we are not taking host & port into consideration

// 	// dags string // location of DAG files (default is /Users/<user>/.prometheus/dags)
// 	// host string // server host (default is localhost)
// 	// port string // server port (default is 8080)
// 	// result := os.execute_opt('prometheus start-all ${flags}')!

// 	mut sm := startupmanager.get()!

// 	sm.start(
// 		name: 'prometheus'
// 		cmd: cmd
// 		env: {
// 			'HOME': '/root'
// 		}
// 	)!

// 	//cmd2 := 'prometheus scheduler' // TODO: do we need this
// 	console.print_debug(cmd)

// 	// if true{
// 	// 	panic("sdsdsds prometheus install")
// 	// }

// 	// time.sleep(100000000000)
// 	for _ in 0 .. 50 {
// 		if check(args)! {
// 			return
// 		}
// 		time.sleep(100 * time.millisecond)
// 	}
// 	return error('prometheus did not install propertly, could not call api.')	

// }

// pub fn configure(args_ InstallArgs) ! {
// 	mut cfg := args_

// 	if cfg.password == "" || cfg.secret == ""{
// 		return error("password and secret needs to be filled in for prometheus")
// 	}

// 	mut mycode := $tmpl('templates/admin.yaml')

// 	mut path := pathlib.get_file(path: cfg.configpath, create: true)!
// 	path.write(mycode)!

// 	console.print_debug(mycode)

// }

// pub fn check(args InstallArgs) !bool {
// 	// this checks health of prometheus
// 	// curl http://localhost:3333/api/v1/s --oauth2-bearer 1234 works
// 	mut conn := httpconnection.new(name: 'prometheus', url: 'http://127.0.0.1:${args.port}/api/v1/')!

// 	// console.print_debug("curl http://localhost:3333/api/v1/dags --oauth2-bearer ${secret}")
// 	if args.secret.len > 0 {
// 		conn.default_header.add(.authorization, 'Bearer ${args.secret}')
// 	}
// 	conn.default_header.add(.content_type, 'application/json')
// 	console.print_debug('check connection to prometheus')
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
// 	sm.stop('prometheus')!
// }

// pub fn restart(args InstallArgs) ! {
// 	stop()!
// 	start(args)!
// }

// pub fn installargs(args InstallArgs) InstallArgs {
// 	return args	
// }
