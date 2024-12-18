#!/usr/bin/env v

import freeflowuniverse.crystallib.sysadmin.dagu
import freeflowuniverse.crystallib.threefold.tfrobot
import os

os.execute_opt('chmod +x ${os.dir(@FILE)}/ping.vsh')!
os.execute_opt('chmod +x ${os.dir(@FILE)}/receive.vsh')!

mut d := dagu.new()!
d.basic_auth('example_username', 'example_password')!
d.new_dag(
	name:  'mycelium'
	steps: [
		dagu.Step{
			name:          'ping'
			command:       '${os.dir(@FILE)}/ping.vsh'
			repeat_policy: dagu.RepeatPolicy{
				repeat:       true
				interval_sec: 5
			}
		},
		dagu.Step{
			name:          'receive'
			command:       '${os.dir(@FILE)}/receive.vsh'
			repeat_policy: dagu.RepeatPolicy{
				repeat:       true
				interval_sec: 5
			}
		},
	]
)
spawn d.start('mycelium')
dagu.server()!
