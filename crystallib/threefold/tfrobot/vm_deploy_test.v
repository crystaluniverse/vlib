module tfrobot

import os
import freeflowuniverse.crystallib.osal


const testdata_dir = '${os.dir(@FILE)}/testdata'

fn testsuite_begin() ! {
	osal.load_env_file('${testdata_dir}/.env')!
}

fn test_vm_deploy() ! {
	mneumonics := os.getenv('MNEUMONICS')
	ssh_key := os.getenv('SSH_KEY')

	mut robot := configure('testrobot', 
		mnemonics: mneumonics
		network: 'main'
	)!
	result := robot.vm_deploy(
		deployment_name: 'test_deployment'
		name: 'test_vm'
		cores: 1
		memory: 256
		pub_sshkeys: [ssh_key]
	)!
	panic(result)

	assert result.name.starts_with('test_vm')
	assert result.yggdrasil_ip.len > 0
	assert result.mycelium_ip.len > 0
}