module playcmds

import freeflowuniverse.crystallib.develop.luadns
import freeflowuniverse.crystallib.core.playbook
import os

pub fn play_luadns(mut plbook playbook.PlayBook) ! {
	_ := '${os.home_dir()}/hero/var/mdbuild'
	_ := '${os.home_dir()}/hero/www/info'
	_ := ''
	// mut install := false
	_ := false
	_ := false

	for mut action in plbook.find(filter: 'luadns.set_domain')! {
		mut p := action.params
		url := p.get_default('url', '')!

		if url == '' {
			return error('luadns url cant be empty')
		}

		mut dns := luadns.load(url)!

		domain := p.get_default('domain', '')!
		ip := p.get_default('ip', '')!

		if domain == '' || ip == '' {
			return error('luadns set domain: domain or ip cant be empty')
		}

		dns.set_domain(domain, ip)!
		action.done = true
	}
}
