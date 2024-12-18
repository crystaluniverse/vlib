module tfrobot

import os
import toml

__global (
	mnemonics string
	ssh_key   string
)

fn testsuite_begin() ! {
	env := toml.parse_file(os.dir(@FILE) + '/.env') or { toml.Doc{} }
	mnemonics = os.getenv_opt('TFGRID_MNEMONIC') or {
		env.value_opt('TFGRID_MNEMONIC') or {
			panic('TFGRID_MNEMONIC variable should either be set as environment variable or set in .env file for this test')
		}.string()
	}
	ssh_key = os.getenv_opt('SSH_KEY') or {
		env.value_opt('SSH_KEY') or {
			panic('SSH_KEY variable should either be set as environment variable or set in .env file for this test')
		}.string()
	}
}

fn test_deploy() ! {
	mut robot := new()!
	result := robot.deploy(
		name:        'test'
		mnemonic:    mnemonics
		network:     .main
		node_groups: [
			NodeGroup{
				name:        'test_group'
				nodes_count: 1
				free_cpu:    1
				free_mru:    256
			},
		]
		vms:         [
			VMConfig{
				name:        'test'
				vms_count:   1
				cpu:         1
				mem:         256
				node_group:  'test_group'
				ssh_key:     'test_key'
				entry_point: '/usr/local/bin/entrypoint.sh'
				flist:       'https://hub.grid.tf/mariobassem1.3bot/threefolddev-holochain-latest.flist'
			},
		]
		ssh_keys:    {
			'test_key': ssh_key
		}
	)!

	assert result.error.keys().len == 0
	assert result.ok.keys() == ['test_group']
	assert result.ok['test_group'].len == 1
	assert result.ok['test_group'][0].name == 'test0'
	assert result.ok['test_group'][0].public_ip4 == ''
	assert result.ok['test_group'][0].public_ip6 == ''
	assert result.ok['test_group'][0].planetary_ip == ''
	assert result.ok['test_group'][0].mounts.len == 0
}
