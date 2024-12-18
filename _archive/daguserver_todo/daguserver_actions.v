module daguserver

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.osal.zinit
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.clients.httpconnection
import os

// checks if a certain version or above is installed
fn installed() !bool {
	res := os.execute('${osal.profile_path_source_and()} dagu version')
	if res.exit_code == 0 {
		r := res.output.split_into_lines().filter(it.trim_space().len > 0)
		if r.len != 1 {
			return error("couldn't parse dagu version.\n${res.output}")
		}
		if texttools.version(version) > texttools.version(r[0]) {
			return false
		}
	} else {
		return false
	}
	return true
}

fn install() ! {
	console.print_header('install dagu')
	mut url := ''
	if osal.is_linux_arm() {
		url = 'https://github.com/dagu-dev/dagu/releases/download/v${version}/dagu_${version}_linux_arm64.tar.gz'
	} else if osal.is_linux_intel() {
		url = 'https://github.com/dagu-dev/dagu/releases/download/v${version}/dagu_${version}_linux_amd64.tar.gz'
	} else if osal.is_osx_arm() {
		url = 'https://github.com/dagu-dev/dagu/releases/download/v${version}/dagu_${version}_darwin_arm64.tar.gz'
	} else if osal.is_osx_intel() {
		url = 'https://github.com/dagu-dev/dagu/releases/download/v${version}/dagu_${version}_darwin_amd64.tar.gz'
	} else {
		return error('unsported platform')
	}

	mut dest := osal.download(
		url:        url
		minsize_kb: 9000
		expand_dir: '/tmp/dagu'
	)!

	mut binpath := dest.file_get('dagu')!
	osal.cmd_add(
		cmdname: 'dagu'
		source:  binpath.path
	)!
}

fn build() ! {
}

fn startupcmd() ![]zinit.ZProcessNewArgs {
	mut res := []zinit.ZProcessNewArgs{}

	res << zinit.ZProcessNewArgs{
		name: 'dagu'
		cmd:  'dagu server'
		env:  {
			'HOME': '/root'
		}
	}

	res << zinit.ZProcessNewArgs{
		name: 'dagu_scheduler'
		cmd:  'dagu scheduler'
		env:  {
			'HOME': '/root'
		}
	}

	return res
}

fn configure() ! {
	mut cfg := get()!

	mut mycode := $tmpl('templates/admin.yaml')

	mut path := pathlib.get_file(path: cfg.configpath, create: true)!
	path.write(mycode)!

	console.print_debug(mycode)
}

fn running() !bool {
	mut cfg := get()!
	// this checks health of dagu
	// curl http://localhost:3333/api/v1/s --oauth2-bearer 1234 works
	url := 'http://127.0.0.1:${cfg.port}/api/v1'
	mut conn := httpconnection.new(name: 'dagu', url: url)!

	if cfg.secret.len > 0 {
		conn.default_header.add(.authorization, 'Bearer ${cfg.secret}')
	}
	conn.default_header.add(.content_type, 'application/json')
	console.print_debug("curl -X 'GET' '${url}'/tags --oauth2-bearer ${cfg.secret}")
	r := conn.get_json_dict(prefix: 'tags', debug: false) or { return false }
	// println(r)
	// if true{panic("ssss")}
	tags := r['Tags'] or { return false }
	// console.print_debug(tags)
	console.print_debug('Dagu is answering.')
	return true
}

fn destroy() ! {
	cmd := '
		systemctl disable dagu_scheduler.service
		systemctl disable dagu.service
		systemctl stop dagu_scheduler.service
		systemctl stop dagu.service

		systemctl list-unit-files | grep dagu

		pkill -9 -f dagu

		ps aux | grep dagu

		'

	osal.exec(cmd: cmd, stdout: true, debug: false)!
}

fn obj_init() ! {
}

fn start_pre() ! {
}

fn start_post() ! {
}

fn stop_pre() ! {
}

fn stop_post() ! {
}
