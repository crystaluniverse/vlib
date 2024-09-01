module ${args.name}

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.osal.zinit
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.clients.httpconnection


import os


// checks if a certain version or above is installed
fn installed() !bool {

	res := os.execute('${osal.profile_path_source_and()} ${args.name} version')
	if res.exit_code == 0 {
		r := res.output.split_into_lines().filter(it.trim_space().len > 0)
		if r.len != 1 {
			return error("couldn't parse ${args.name} version.\n${res.output}")
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
	console.print_header('install ${args.name}')
	mut url := ''
	if osal.is_linux_arm() {
		url = 'https://github.com/${args.name}-dev/${args.name}/releases/download/v${version}/${args.name}_${version}_linux_arm64.tar.gz'
	} else if osal.is_linux_intel() {
		url = 'https://github.com/${args.name}-dev/${args.name}/releases/download/v${version}/${args.name}_${version}_linux_amd64.tar.gz'
	} else if osal.is_osx_arm() {
		url = 'https://github.com/${args.name}-dev/${args.name}/releases/download/v${version}/${args.name}_${version}_darwin_arm64.tar.gz'
	} else if osal.is_osx_intel() {
		url = 'https://github.com/${args.name}-dev/${args.name}/releases/download/v${version}/${args.name}_${version}_darwin_amd64.tar.gz'
	} else {
		return error('unsported platform')
	}

	mut dest := osal.download(
		url: url
		minsize_kb: 9000
		expand_dir: '/tmp/${args.name}'
	)!

	mut binpath := dest.file_get('${args.name}')!
	osal.cmd_add(
		cmdname: '${args.name}'
		source: binpath.path
	)!
}

@if args.daemon
fn startupcmd () ![]zinit.ZProcessNewArgs{
	mut res := []zinit.ZProcessNewArgs{}

	res << zinit.ZProcessNewArgs{
		name: '${args.name}'
		cmd: '${args.name} server'
		env: {
			'HOME': '/root'
		}	
	}

	return res
	
}
@end

fn configure() ! {
	mut cfg := get()!
@if args.templates
	mut mycode := $tmpl('templates/admin.yaml')
	mut path := pathlib.get_file(path: cfg.configpath, create: true)!
	path.write(mycode)!
	console.print_debug(mycode)
@else
	//implement if steps need to be done for configuration
@end	
}




fn running() !bool {
	mut cfg := get()!
	// this checks health of ${args.name}
	// curl http://localhost:3333/api/v1/s --oauth2-bearer 1234 works
	url:='http://127.0.0.1:${cfg.port}/api/v1'
	mut conn := httpconnection.new(name: '${args.name}', url: url)!

	if cfg.secret.len > 0 {
		conn.default_header.add(.authorization, 'Bearer ${cfg.secret}')
	}
	conn.default_header.add(.content_type, 'application/json')
	console.print_debug("curl -X 'GET' '${url}'/tags --oauth2-bearer ${cfg.secret}")
	r := conn.get_json_dict(prefix: 'tags', debug: false) or {return false}
	// println(r)
	// if true{panic("ssss")}
	tags := r['Tags'] or { return false }
	// console.print_debug(tags)
	console.print_debug('Dagu is answering.')
	return true
}



fn destroy() ! {
	cmd:="
		systemctl disable ${args.name}_scheduler.service
		systemctl disable ${args.name}.service
		systemctl stop ${args.name}_scheduler.service
		systemctl stop ${args.name}.service

		systemctl list-unit-files | grep ${args.name}

		pkill -9 -f ${args.name}

		ps aux | grep ${args.name}

		"
	
	osal.exec(cmd: cmd, stdout:true, debug: false)!
}


fn obj_init()!{

}


fn start_pre()!{
	
}

fn start_post()!{
	
}

fn stop_pre()!{
	
}

fn stop_post()!{
	
}

