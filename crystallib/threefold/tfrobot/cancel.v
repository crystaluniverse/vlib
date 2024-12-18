module tfrobot

import json
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.osal

pub struct CancelConfig {
mut:
	name        string        @[required]
	mnemonic    string        @[required]
	network     Network       @[required]
	node_groups []CancelGroup @[required]
}

pub struct CancelGroup {
	name string @[required]
}

pub fn (mut robot TFRobot[Config]) cancel(mut config CancelConfig) ! {
	cfg := robot.config()!
	if config.mnemonic == '' {
		config.mnemonic = cfg.mnemonics
	}
	config.network = Network.from(cfg.network)!
	check_cancel_config(config)!

	mut cancel_file := pathlib.get_file(
		path:   '${tfrobot_dir}/deployments/${config.name}_cancel.json'
		create: true
	)!

	cancel_file.write(json.encode(config))!
	osal.exec(
		cmd:    'tfrobot cancel -c ${cancel_file.path}'
		stdout: true
	)!
}

fn check_cancel_config(config CancelConfig) ! {
	if config.node_groups.len == 0 {
		return error('No node groups specified to cancel.')
	}
	if config.node_groups.any(it.name == '') {
		return error('Cannot cancel deployment without node_group name.')
	}
}
