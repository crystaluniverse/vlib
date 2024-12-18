module caddy

import freeflowuniverse.crystallib.core.playbook
import os

pub fn play(mut plbook playbook.PlayBook) ! {
	// base.play(plbook)!

	caddy_actions := plbook.find(filter: 'caddy.')!
	if caddy_actions.len == 0 {
		return
	}

	mut install_actions := plbook.find(filter: 'caddy.install')!

	if install_actions.len > 0 {
		for install_action in install_actions {
			mut p := install_action.params

			reset := p.get_default_false('reset')
			start := p.get_default_true('start')
			restart := p.get_default_false('restart')
			stop := p.get_default_false('stop')
			homedir := p.get_default('homedir', '${os.home_dir()}/hero/www')!
			file_path := p.get_default('file_path', '')!
			file_url := p.get_default('file_url', '')!
			xcaddy := p.get_default_false('xcaddy')
			mut plugins := p.get_list_default('plugins', [])!

			if xcaddy {
				if plugins == [] {
					plugins = ['github.com/mholt/caddy-webdav', 'github.com/mohammed90/caddy-git-fs',
						'github.com/abiosoft/caddy-exec', 'github.com/greenpau/caddy-security']
				}
			}

			install(
				reset:     reset
				start:     start
				restart:   restart
				stop:      stop
				homedir:   homedir
				file_path: file_path
				file_url:  file_url
				xcaddy:    xcaddy
				plugins:   plugins
			)!
		}
	}
}
