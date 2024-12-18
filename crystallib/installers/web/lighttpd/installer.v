module lighttpd

import freeflowuniverse.crystallib.installers.base
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.installers.infra.zinit
import freeflowuniverse.crystallib.osal.zinit as zinitmgmt
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.osal.screen
import os

@[params]
pub struct InstallArgs {
pub mut:
	reset       bool
	letsencrypt bool
}

// install lighttpd will return true if it was already installed
pub fn install(args InstallArgs) ! {
	// make sure we install base on the node
	base.install()!

	if args.reset == false && osal.done_exists('install_lighttpd') {
		return
	}

	if !osal.is_linux() {
		return error('only support linux for now')
	}

	osal.package_install('lighttpd')! // lego is for letsencrypt

	if args.letsencrypt {
		osal.package_install('lego')! // lego is for letsencrypt
	}

	// install lighttpd if it was already done will return true
	console.print_header('package install lighttpd')

	console.print_debug(' lighttpd installed')

	osal.done_set('install_lighttpd', 'OK')!
	return
}

@[params]
pub struct WebConfig {
pub mut:
	path string = '/var/www'
}

// configure lighttpd as default webserver & start
// node, path, domain
// path e.g. /var/www
// domain e.g. www.myserver.com
pub fn install_configure_default(config WebConfig) ! {
	mut config_file := $tmpl('templates/lighttpd.conf')
	// if config.domain.len > 0 {
	// 	config_file = $tmpl('templates/lighttpdfile_domain')
	// }
	install(letsencrypt: true)!
	os.mkdir_all(config.path)!

	default_html := '
	<!DOCTYPE html>
	<html>
		<head>
			<title>Lighttpd has now been installed.</title>
		</head>
		<body>
			Lighttpd has been installed and is working in /var/www.
		</body>
	</html>
	'
	osal.file_write('${config.path}/index.html', default_html)!

	configuration_set(content: config_file)!

	console.print_debug(' INSTALL LIGHTTPD OK ON PORT 8000')
}

pub fn configuration_get() !string {
	c := osal.file_read('/etc/lighttpd/lighttpd.conf')!
	return c
}

@[params]
pub struct ConfigurationArgs {
pub mut:
	content string
	path    string
	restart bool = true
}

pub fn configuration_set(args_ ConfigurationArgs) ! {
	console.print_header('Lighttpd config set')
	mut args := args_
	if args.content == '' && args.path == '' {
		return error('need to specify content or path.')
	}
	if args.content.len > 0 {
		args.content = texttools.dedent(args.content)
		if !os.exists('/etc/lighttpd') {
			os.mkdir_all('/etc/lighttpd')!
		}
		osal.file_write('/etc/lighttpd/lighttpd.conf', args.content)!
	} else {
		mut p := pathlib.get_file(path: args.path, create: true)!
		content := p.read()!
		if !os.exists('/etc/lighttpd') {
			os.mkdir_all('/etc/lighttpd')!
		}
		osal.file_write('/etc/lighttpd/lighttpd.conf', content)!
	}

	if args.restart {
		restart()!
	}
}

@[params]
pub struct StartArgs {
pub mut:
	zinit bool
}

// start lighttpd
pub fn start(args StartArgs) ! {
	console.print_header('Lighttpd Start')
	if !os.exists('/etc/lighttpd/lighttpd.conf') {
		return error("didn't find lighttpdfile")
	}
	if args.zinit {
		zinit.install()!
		mut z := zinitmgmt.new()!
		p := z.process_new(
			name: 'lighttpd'
			cmd:  '
				lighttpd -D -f /etc/lighttpd/lighttpd.conf
				echo LIGHTTPD STOPPED
				/bin/bash'
		)!

		p.start()!
	} else {
		mut scr := screen.new(reset: false)!
		_ = scr.add(name: 'lighttpd', cmd: 'lighttpd -D -f /etc/lighttpd/lighttpd.conf')!
	}
}

pub fn stop() ! {
	console.print_header('Lighttpd Stop')
	mut scr := screen.new(reset: false)!
	scr.kill('lighttpd')!
	// osal.process_kill_recursive(name:"lighttpd")! //kills myself
}

pub fn restart() ! {
	stop()!
	start()!
}
