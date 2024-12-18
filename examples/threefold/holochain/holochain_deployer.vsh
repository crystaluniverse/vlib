#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.threefold.tfrobot
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.clients.dagu

console.print_header('Deploy test of vmachines on TFGrid using TFRobot.')

mut bot := tfrobot.new()!

mut deploy_config := tfrobot.DeployConfig{
	name:        'holotest2'
	network:     .main
	debug:       true
	node_groups: [
		tfrobot.NodeGroup{
			name:        'hologroup2'
			nodes_count: 20
			free_cpu:    8
			free_mru:    8
			free_ssd:    100
			// region:"europe"
		},
	]
	vms:         [
		tfrobot.VMConfig{
			name:        'myvm'
			vms_count:   5
			cpu:         1
			mem:         1
			entry_point: '/sbin/zinit init'
			// flist: 'https://hub.grid.tf/mariobassem1.3bot/threefolddev-holochain-latest.flist'
			flist:      'https://hub.grid.tf/ashraf.3bot/threefolddev-holochain-latest.flist'
			env_vars:   {
				'CODE_SERVER_PASSWORD':    'planetfirst'
				'DAGU_BASICAUTH_USERNAME': 'admin'
				'DAGU_BASICAUTH_PASSWORD': 'planetfirst'
			}
			public_ip4: false
			root_size:  50
			planetary:  true
		},
	]
}

// ssh-key is not specified, first key will be chosen

// DEAL WITH SSH KEYS
tfrobot.sshagent_keys_add(mut deploy_config)!

console.print_header('nr of ssh keys in ssh-agent:${deploy_config.ssh_keys.len}')

res := bot.deploy(deploy_config)!

console.print_header("Get VM's and ssh into it.")

for vm in tfrobot.vms_get('holotest')! {
	console.print_debug(vm.str())
	mut node := vm.node()!
	r := node.exec(cmd: 'ls /')!
	println(r)
}
