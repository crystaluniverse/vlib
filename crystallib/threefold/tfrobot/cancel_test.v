module tfrobot

import os
import toml

__global (
	mnemonics string
	ssh_key   string
)

const test_name = 'cancel_test'
const test_flist = 'https://hub.grid.tf/mariobassem1.3bot/threefolddev-holochain-latest.flist'
const test_entrypoint = '/usr/local/bin/entrypoint.sh'

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

fn test_cancel() ! {
	mut robot := new()!
	result := robot.deploy(
		name:        '${test_name}_deployment'
		mnemonic:    mnemonics
		network:     .main
		node_groups: [
			NodeGroup{
				name:        '${test_name}_group'
				nodes_count: 1
				free_cpu:    1
				free_mru:    256
			},
		]
		vms:         [
			VMConfig{
				name:        '${test_name}_vm'
				vms_count:   1
				cpu:         1
				mem:         256
				node_group:  '${test_name}_group'
				ssh_key:     '${test_name}_key'
				entry_point: test_entrypoint
				flist:       test_flist
			},
		]
		ssh_keys:    {
			'${test_name}_key': ssh_key
		}
	)!

	assert result.ok.keys() == ['${test_name}_group']
	robot.cancel(
		name:        '${test_name}_deployment'
		mnemonic:    mnemonics
		network:     .main
		node_groups: [CancelGroup{
			name: '${test_name}_group'
		}]
	)!
}
