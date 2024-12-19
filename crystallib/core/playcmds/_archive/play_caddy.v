module playcmds

// import freeflowuniverse.crystallib.installers.web.caddy as caddy_installer
// import freeflowuniverse.crystallib.servers.caddy { CaddyFile }
// import freeflowuniverse.crystallib.core.playbook
// import os
// // import net.urllib

// pub fn play_caddy(mut plbook playbook.PlayBook) ! {
// 	play_caddy_basic(mut plbook)!
// 	play_caddy_configure(mut plbook)!
// }

// pub fn play_caddy_configure(mut plbook playbook.PlayBook) ! {
// 	mut caddy_actions := plbook.find(filter: 'caddy_configure')!
// 	if caddy_actions.len == 0 {
// 		return
// 	}
// }

// pub fn play_caddy_basic(mut plbook playbook.PlayBook) ! {
// 	caddy_actions := plbook.find(filter: 'caddy.')!
// 	if caddy_actions.len == 0 {
// 		return
// 	}

// 	mut install_actions := plbook.find(filter: 'caddy.install')!

// 	if install_actions.len > 0 {
// 		for install_action in install_actions {
// 			mut p := install_action.params
// 			xcaddy := p.get_default_false('xcaddy')
// 			file_path := p.get_default('file_path', '/etc/caddy')!
// 			file_url := p.get_default('file_url', '')!
// 			reset := p.get_default_false('reset')
// 			start := p.get_default_false('start')
// 			restart := p.get_default_false('restart')
// 			stop := p.get_default_false('stop')
// 			homedir := p.get_default('file_url', '')!
// 			plugins := p.get_list_default('plugins', []string{})!

// 			caddy_installer.install(
// 				xcaddy: xcaddy
// 				file_path: file_path
// 				file_url: file_url
// 				reset: reset
// 				start: start
// 				restart: restart
// 				stop: stop
// 				homedir: homedir
// 				plugins: plugins
// 			)!
// 		}
// 	}

// 	mut config_actions := plbook.find(filter: 'caddy.configure')!
// 	if config_actions.len > 0 {
// 		mut coderoot := ''
// 		mut reset := false
// 		mut pull := false

// 		mut public_ip := ''

// 		mut c := caddy.get('')!
// 		// that to me seems to be wrong, not generic enough
// 		if config_actions.len > 1 {
// 			return error('can only have 1 config action for books')
// 		} else if config_actions.len == 1 {
// 			mut p := config_actions[0].params
// 			path := p.get_default('path', '/etc/caddy')!
// 			url := p.get_default('url', '')!
// 			public_ip = p.get_default('public_ip', '')!
// 			c = caddy.configure('', homedir: path)!
// 			config_actions[0].done = true
// 		}

// 		mut caddyfile := CaddyFile{}
// 		for mut action in plbook.find(filter: 'caddy.add_reverse_proxy')! {
// 			mut p := action.params
// 			mut from := p.get_default('from', '')!
// 			mut to := p.get_default('to', '')!

// 			if from == '' || to == '' {
// 				return error('from & to cannot be empty')
// 			}

// 			caddyfile.add_reverse_proxy(
// 				from: from
// 				to: to
// 			)!
// 			action.done = true
// 		}

// 		for mut action in plbook.find(filter: 'caddy.add_file_server')! {
// 			mut p := action.params
// 			mut domain := p.get_default('domain', '')!
// 			mut root := p.get_default('root', '')!

// 			if root.starts_with('~') {
// 				root = '${os.home_dir()}${root.trim_string_left('~')}'
// 			}

// 			if domain == '' || root == '' {
// 				return error('domain & root cannot be empty')
// 			}

// 			caddyfile.add_file_server(
// 				domain: domain
// 				root: root
// 			)!
// 			action.done = true
// 		}

// 		for mut action in plbook.find(filter: 'caddy.add_basic_auth')! {
// 			mut p := action.params
// 			mut domain := p.get_default('domain', '')!
// 			mut username := p.get_default('username', '')!
// 			mut password := p.get_default('password', '')!

// 			if domain == '' || username == '' || password == '' {
// 				return error('domain & root cannot be empty')
// 			}

// 			caddyfile.add_basic_auth(
// 				domain: domain
// 				username: username
// 				password: password
// 			)!
// 			action.done = true
// 		}

// 		for mut action in plbook.find(filter: 'caddy.generate')! {
// 			c.set_caddyfile(caddyfile)!
// 			action.done = true
// 		}

// 		for mut action in plbook.find(filter: 'caddy.start')! {
// 			c.start()!
// 			action.done = true
// 		}
// 		c.reload()!
// 	}
// }
