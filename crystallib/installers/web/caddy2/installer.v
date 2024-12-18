module caddy

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.sysadmin.startupmanager
import freeflowuniverse.crystallib.installers.lang.golang
import os

pub const version = '2.8.4'

@[params]
pub struct InstallArgs {
pub mut:
	reset     bool
	start     bool
	restart   bool
	stop      bool
	homedir   string = '/var/www'
	file_path string   // path to caddyfile
	file_url  string   // path to caddyfile
	xcaddy    bool     // wether to install caddy with xcaddy
	plugins   []string // list of plugins to build caddy with
}

// install caddy will return true if it was already installed
pub fn install(args_ InstallArgs) ! {
	mut args := args_
	version := '2.8.4'

	installed := is_installed(version)!

	if args.reset || !installed {
		console.print_header('install caddy')
		if args.xcaddy || args.plugins.len > 0 {
			golang.install()!
			install_caddy_with_xcaddy(args.plugins)!
		} else {
			install_caddy_from_release()!
		}
	} else if args.plugins.any(!plugin_is_installed(it)!) {
		golang.install()!
		install_caddy_with_xcaddy(args.plugins)!
	}

	if args.restart {
		restart(args)!
		return
	}

	if args.start {
		start(args)!
	}
}

pub fn is_installed(version string) !bool {
	res := os.execute('${osal.profile_path_source_and()} caddy version')
	if res.exit_code == 0 {
		mut r := res.output.split_into_lines().filter(it.trim_space().len > 0)
		if r.len > 1 {
			r = r.filter(it.starts_with('v'))
		}
		if r.len != 1 {
			return error("couldn't parse caddy version.\n${r}")
		}
		if texttools.version(version) > texttools.version(r[0]) {
			return false
		}
		return true
	}
	return false
}

pub fn install_caddy_from_release() ! {
	version := '2.8.4'
	mut url := ''
	if osal.is_linux_arm() {
		url = 'https://github.com/caddyserver/caddy/releases/download/v${version}/caddy_${version}_linux_arm64.tar.gz'
	} else if osal.is_linux_intel() {
		url = 'https://github.com/caddyserver/caddy/releases/download/v${version}/caddy_${version}_linux_amd64.tar.gz'
	} else if osal.is_osx_arm() {
		url = 'https://github.com/caddyserver/caddy/releases/download/v${version}/caddy_${version}_darwin_arm64.tar.gz'
	} else if osal.is_osx_intel() {
		url = 'https://github.com/caddyserver/caddy/releases/download/v${version}/caddy_${version}_darwin_amd64.tar.gz'
	} else {
		return error('unsported platform')
	}

	mut dest := osal.download(
		url:        url
		minsize_kb: 10000
		expand_dir: '/tmp/caddyserver'
	)!

	mut binpath := dest.file_get('caddy')!
	osal.cmd_add(
		cmdname: 'caddy'
		source:  binpath.path
	)!
}

pub fn plugin_is_installed(plugin_ string) !bool {
	plugin := plugin_.trim_space()
	result := osal.exec(cmd: 'caddy list-modules --packages')!

	mut lines := result.output.split('\n')

	mut standardard_packages := []string{}
	mut nonstandardard_packages := []string{}

	mut standard := true
	for mut line in lines {
		line = line.trim_space()
		if line == '' {
			continue
		}
		if line.starts_with('Standard modules') {
			standard = false
			continue
		}
		package := line.all_after(' ')
		if standard {
			standardard_packages << package
		} else {
			nonstandardard_packages << package
		}
	}

	return plugin in standardard_packages || plugin in nonstandardard_packages
}

pub fn install_caddy_with_xcaddy(plugins []string) ! {
	xcaddy_version := '0.4.2'
	caddy_version := '2.8.4'

	console.print_header('Installing xcaddy')
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

	plugins_str := plugins.map('--with ${it}').join(' ')

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

@[params]
pub struct WebConfig {
pub mut:
	path   string = '/var/www'
	domain string
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
	install()!
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

pub fn configuration_get() !string {
	c := osal.file_read('/etc/caddy/Caddyfile')!
	return c
}

@[params]
pub struct ConfigurationArgs {
pub mut:
	content string // caddyfile content
	path    string
	restart bool = true
}

pub fn configuration_set(args_ ConfigurationArgs) ! {
	console.print_header('Caddy config set')
	mut args := args_
	if args.content == '' && args.path == '' {
		return error('need to specify content or path.')
	}
	if args.content.len > 0 {
		args.content = texttools.dedent(args.content)
		if !os.exists('/etc/caddy') {
			os.mkdir_all('/etc/caddy')!
		}
		osal.file_write('/etc/caddy/Caddyfile', args.content)!
	} else {
		mut p := pathlib.get_file(path: args.path, create: true)!
		content := p.read()!
		if !os.exists('/etc/caddy') {
			os.mkdir_all('/etc/caddy')!
		}
		osal.file_write('/etc/caddy/Caddyfile', content)!
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

// start caddy
pub fn start(args_ InstallArgs) ! {
	mut args := args_
	console.print_header('caddy start')

	if args.homedir == '' {
		args.homedir = '/var/www'
	}

	if !os.exists('/etc/caddy/Caddyfile') {
		// set the default caddyfile
		configure_examples(path: args.homedir)!
	}

	cmd := 'caddy run --config /etc/caddy/Caddyfile'

	mut sm := startupmanager.get()!

	sm.new(
		name:  'caddy'
		cmd:   cmd
		start: true
	)!
}

pub fn stop() ! {
	console.print_header('Caddy Stop')
	mut sm := startupmanager.get()!
	sm.stop('caddy')!
}

pub fn restart(args InstallArgs) ! {
	stop()!
	start(args)!
}
