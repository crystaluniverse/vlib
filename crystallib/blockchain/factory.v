module blockchain

import freeflowuniverse.crystallib.core.playbook

@[params]
pub struct PlayArgs {
pub mut:
	name       string = 'default'
	heroscript string // if filled in then plbook will be made out of it
	path       string
	plbook     ?playbook.PlayBook
	// reset      bool
}

pub fn play(args_ PlayArgs) ! {
	mut args := args_

	mut plbook := args.plbook or { playbook.new(text: args.heroscript, path: args.path)! }

	mut myactions := plbook.find(filter: 'blockchain.account')!
	if myactions.len > 0 {
		for install_action in myactions {
			mut p := install_action.params
			play_asset(p)!
		}
	}
}
