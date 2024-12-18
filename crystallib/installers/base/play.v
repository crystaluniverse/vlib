module base

import freeflowuniverse.crystallib.core.playbook
import os

pub fn play(mut plbook playbook.PlayBook) ! {
	base_actions := plbook.find(filter: 'base.')!
	if base_actions.len == 0 {
		return
	}

	mut install_actions := plbook.find(filter: 'base.install')!

	if install_actions.len > 0 {
		for install_action in install_actions {
			mut p := install_action.params

			reset := p.get_default_false('reset')
			develop := p.get_default_false('develop')

			install(
				reset:   reset
				develop: develop
			)!
		}
	}
}
