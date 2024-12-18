#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.threefold.grid.models
import freeflowuniverse.crystallib.threefold.grid as tfgrid
import log
import os

fn test_deploy_vm_hight_level(node_id u32) ! {
	mnemonics := tfgrid.get_mnemonics()!
	chain_network := tfgrid.ChainNetwork.dev // User your desired network

	mut logger := &log.Log{}
	logger.set_level(.debug)

	mut deployer := tfgrid.new_deployer(mnemonics, chain_network, mut logger)!

	vm := models.VM{
		name:     'vm1'
		env_vars: {
			'SSH_KEY': 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDTwULSsUubOq3VPWL6cdrDvexDmjfznGydFPyaNcn7gAL9lRxwFbCDPMj7MbhNSpxxHV2+/iJPQOTVJu4oc1N7bPP3gBCnF51rPrhTpGCt5pBbTzeyNweanhedkKDsCO2mIEh/92Od5Hg512dX4j7Zw6ipRWYSaepapfyoRnNSriW/s3DH/uewezVtL5EuypMdfNngV/u2KZYWoeiwhrY/yEUykQVUwDysW/xUJNP5o+KSTAvNSJatr3FbuCFuCjBSvageOLHePTeUwu6qjqe+Xs4piF1ByO/6cOJ8bt5Vcx0bAtI8/MPApplUU/JWevsPNApvnA/ntffI+u8DCwgP'
		}
	}
	res := deployer.client.deploy_single_vm(node_id, 'myproject', vm, deployer.env)!

	deployer.logger.info('${res}')
}

fn main() {
	test_deploy_vm_hight_level(u32(14)) or { println('error happened: ${err}') }
}
