module grid

import freeflowuniverse.crystallib.installers.threefold.griddriver
import os

fn testsuite_begin() ! {
	griddriver.install()!
}

fn test_vm_deploy() ! {
	mnemonics := os.getenv('TFGRID_MNEMONIC')
	ssh_key := os.getenv('SSH_KEY')

	chain_network := ChainNetwork.main // User your desired network
	mut deployer := new_deployer(mnemonics, chain_network)!
	deployer.vm_deploy(
		name:            'test_vm'
		deployment_name: 'test_deployment'
		nodeid:          24
		pub_sshkeys:     [ssh_key]
	)!
}
