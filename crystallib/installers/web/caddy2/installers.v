module caddy

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.ui.console

pub fn install_caddy_from_release() ! {
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

pub fn install_caddy_with_xcaddy(plugins []string) ! {
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
