module base

import freeflowuniverse.crystallib.core.playbook
import os

fn git_configure(name string, email string) ! {
	os.execute_or_panic('git config --global user.name "${name}"')
	os.execute_or_panic('git config --global user.email "${email}"')
}

pub fn play(mut plbook playbook.PlayBook) ! {
	base_actions := plbook.find(filter: 'base.')!
	if base_actions.len == 0 {
		return
	}

	mut install_actions := plbook.find(filter: 'base.install')!
	mut git_config_actions := plbook.find(filter: 'base.git_configure')!

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

	if git_config_actions.len > 0 {
		for git_action in git_config_actions {
			mut p := git_action.params

			name := p.get('name')!
			email := p.get('email')!

			git_configure(name, email)!
		}
	}
}
