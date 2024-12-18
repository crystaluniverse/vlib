module rclone

import freeflowuniverse.crystallib.core.playbook
import freeflowuniverse.crystallib.core.texttools

const configfile = '${HOME}/.config/rclone/rclone.conf'

// will look for personal configuration file in ~/hero/config .
// this file is in heroscript format and will have all required info to configure rclone
//```
// !!config.s3server_define
//     name:'tf_write_1'
//     description:'ThreeFold Read Write Repo 1
//     keyid:'003e2a7be6357fb0000000001'
//     keyname:'tfrw'
//     appkey:'K003UsdrYOZou2ulBHA8p4KLa/dL2n4'
//     url:''
//```
pub fn configure() ! {
	actions := playbook.new(
		path:          configfile
		actor_filter:  ['config']
		action_filter: [
			's3server_define',
		]
	)!
	mut out := ''
	for action in actions {
		mut name := action.params.get_default('name', '')!
		mut descr := action.params.get_default('descr', '')!
		mut config := '
		[${name}]
		type = b2
		account = e2a7be6357fb
		hard_delete = true
		key = 003b79a6ae62cd7cb04477834a24e007e7afc601ba
		'
		config = texttools.dedent(config)
		out += '\n${config}\n'
	}
}
