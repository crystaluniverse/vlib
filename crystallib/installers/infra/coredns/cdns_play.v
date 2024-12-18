module coredns

import freeflowuniverse.crystallib.core.playbook
import freeflowuniverse.crystallib.installers.base
import os

pub fn play(mut plbook playbook.PlayBook) ! {
	base.play(playbook)!

	coredns_actions := plbook.find(filter: 'coredns.')!
	if coredns_actions.len == 0 {
		return
	}

	mut install_actions := plbook.find(filter: 'coredns.install')!

	if install_actions.len > 0 {
		for install_action in install_actions {
			mut p := install_action.params

			// CoreDNS parameters
			reset := p.get_default_false('reset')
			start := p.get_default_true('start')
			stop := p.get_default_false('stop')
			restart := p.get_default_false('restart')
			homedir := p.get_default('homedir', '${os.home_dir()}/hero/var/coredns')!
			config_path := p.get_default('config_path', '${os.home_dir()}/hero/cfg/Corefile')!
			config_url := p.get_default('config_url', '')!
			dnszones_path := p.get_default('dnszones_path', '${os.home_dir()}/hero/var/coredns/zones')!
			dnszones_url := p.get_default('dnszones_url', '')!
			plugins := p.get_list_default('plugins', [])!
			example := p.get_default_false('example')

			install(
				reset:         reset
				start:         start
				stop:          stop
				restart:       restart
				homedir:       homedir
				config_path:   config_path
				config_url:    config_url
				dnszones_path: dnszones_path
				dnszones_url:  dnszones_url
				plugins:       plugins
				example:       example
			)!
		}
	}
}
