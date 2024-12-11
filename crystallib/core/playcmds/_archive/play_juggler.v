module playcmds

import freeflowuniverse.crystallib.data.doctree
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.playbook
import freeflowuniverse.crystallib.develop.juggler
import os

pub fn play_juggler(mut plbook playbook.PlayBook) ! {
	mut coderoot := ''
	// mut install := false
	mut reset := false
	mut pull := false

	mut config_actions := plbook.find(filter: 'juggler.configure')!

	mut j := juggler.Juggler{}

	if config_actions.len > 1 {
		return error('can only have 1 config action for juggler')
	} else if config_actions.len == 1 {
		mut p := config_actions[0].params
		path := p.get_default('path', '/etc/juggler')!
		url := p.get_default('url', '')!
		username := p.get_default('username', '')!
		password := p.get_default('password', '')!
		port := p.get_int_default('port', 8000)!

		j = juggler.configure(
			url: 'https://git.ourworld.tf/projectmycelium/itenv'
			username: username
			password: password
			reset: true
		)!
		config_actions[0].done = true
	}

	for mut action in plbook.find(filter: 'juggler.start')! {
		j.start()!
		action.done = true
	}

	for mut action in plbook.find(filter: 'juggler.restart')! {
		j.restart()!
		action.done = true
	}
}
