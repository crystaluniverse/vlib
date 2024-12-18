module caddy

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.osal.zinit
import os

// checks if a certain version or above is installed
fn installed() !bool {
	// THIS IS EXAMPLE CODEAND NEEDS TO BE CHANGED
	// res := os.execute('${osal.profile_path_source_and()} caddy version')
	// if res.exit_code != 0 {
	//     return false
	// }
	// r := res.output.split_into_lines().filter(it.trim_space().len > 0)
	// if r.len != 1 {
	//     return error("couldn't parse caddy version.\n${res.output}")
	// }
	// if texttools.version(version) > texttools.version(r[0]) {
	//     return false
	// }
	return true
}

fn install() ! {
	console.print_header('install caddy')

	mut cfg := get()!

	mut url := ''
	if osal.is_linux_arm() {
		url = 'https://github.com/caddyserver/xcaddy/releases/download/v${xcaddy_version}/xcaddy_${xcaddy_version}_linux_arm64.tar.gz'
	} else if osal.is_linux_intel() {
		url = 'https://github.com/caddyserver/xcaddy/releases/download/v${xcaddy_version}/xcaddy_${xcaddy_version}_linux_amd64.tar.gz'
	} else if osal.is_osx_arm() {
		url = 'https://github.com/caddyserver/xcaddy/releases/download/v${xcaddy_version}/xcaddy_${xcaddy_version}_mac_arm64.tar.gz'
	} else if osal.is_osx_intel() {
		url = 'https://github.com/caddyserver/xcaddy/releases/download/v${xcaddy_version}/xcaddy_${xcaddy_version}_mac_amd64.tar.gz'
	} else {
		return error('unsported platform')
	}

	mut dest := osal.download(
		url:        url
		minsize_kb: 1000
		expand_dir: '/tmp/xcaddy_dir'
	)!

	mut binpath := dest.file_get('xcaddy')!
	osal.cmd_add(
		cmdname: 'xcaddy'
		source:  binpath.path
	)!

	console.print_header('Installing Caddy with xcaddy')

	plugins_str := cfg.plugins.map('--with ${it}').join(' ')

	// Define the xcaddy command to build Caddy with plugins
	path := '/tmp/caddyserver/caddy'
	cmd := 'source ${osal.profile_path()} && xcaddy build v${caddy_version} ${plugins_str} --output ${path}'
	osal.exec(cmd: cmd)!
	osal.cmd_add(
		cmdname: 'caddy'
		source:  path
		reset:   true
	)!
}

fn startupcmd() ![]zinit.ZProcessNewArgs {
	mut res := []zinit.ZProcessNewArgs{}
	res << zinit.ZProcessNewArgs{
		name: 'caddy'
		cmd:  'caddy run --config /etc/caddy/Caddyfile'
	}
	return res
}

// user needs to us switch to make sure we get the right object
fn configure() ! {
	mut cfg := get()!

	if !os.exists('/etc/caddy/Caddyfile') {
		// set the default caddyfile
		configure_examples(path: cfg.path)!
	}
}

// configure caddy as default webserver & start
// node, path, domain
// path e.g. /var/www
// domain e.g. www.myserver.com
pub fn configure_examples(config WebConfig) ! {
	mut config_file := $tmpl('templates/caddyfile_default')
	if config.domain.len > 0 {
		config_file = $tmpl('templates/caddyfile_domain')
	}
	os.mkdir_all(config.path)!

	default_html := '
	<!DOCTYPE html>
	<html>
		<head>
			<title>Caddy has now been installed.</title>
		</head>
		<body>
			Caddy has been installed and is working in /var/www.
		</body>
	</html>
	'
	osal.file_write('${config.path}/index.html', default_html)!

	configuration_set(content: config_file)!
}

fn running() !bool {
	mut cfg := get()!

	// THIS IS EXAMPLE CODEAND NEEDS TO BE CHANGED

	// this checks health of caddy
	// curl http://localhost:3333/api/v1/s --oauth2-bearer 1234 works
	// url:='http://127.0.0.1:${cfg.port}/api/v1'
	// mut conn := httpconnection.new(name: 'caddy', url: url)!

	// if cfg.secret.len > 0 {
	//     conn.default_header.add(.authorization, 'Bearer ${cfg.secret}')
	// }
	// conn.default_header.add(.content_type, 'application/json')
	// console.print_debug("curl -X 'GET' '${url}'/tags --oauth2-bearer ${cfg.secret}")
	// r := conn.get_json_dict(prefix: 'tags', debug: false) or {return false}
	// println(r)
	// if true{panic("ssss")}
	// tags := r['Tags'] or { return false }
	// console.print_debug(tags)
	// console.print_debug('caddy is answering.')
	return true
}

fn destroy() ! {
	// THIS IS EXAMPLE CODEAND NEEDS TO BE CHANGED
	// cmd:="
	//     systemctl disable caddy_scheduler.service
	//     systemctl disable caddy.service
	//     systemctl stop caddy_scheduler.service
	//     systemctl stop caddy.service

	//     systemctl list-unit-files | grep caddy

	//     pkill -9 -f caddy

	//     ps aux | grep caddy

	//     "

	// osal.exec(cmd: cmd, stdout:true, debug: false)!
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
