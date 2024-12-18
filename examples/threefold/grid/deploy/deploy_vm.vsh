#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.threefold.grid.models
import freeflowuniverse.crystallib.threefold.grid as tfgrid
import json
import log
import os

fn main() {
	mut logger := &log.Log{}
	logger.set_level(.debug)
	mnemonics := os.getenv('TFGRID_MNEMONIC')
	chain_network := tfgrid.ChainNetwork.dev // User your desired network
	mut deployer := tfgrid.new_deployer(mnemonics, chain_network, mut logger)!

	node_id := u32(14)
	network_name := 'network1'
	wg_port := deployer.assign_wg_port(node_id)!
	mut network := models.Znet{
		ip_range:              '10.1.0.0/16'
		subnet:                '10.1.1.0/24'
		wireguard_private_key: 'GDU+cjKrHNJS9fodzjFDzNFl5su3kJXTZ3ipPgUjOUE='
		wireguard_listen_port: wg_port
		peers:                 [
			models.Peer{
				subnet:               '10.1.2.0/24'
				wireguard_public_key: '4KTvZS2KPWYfMr+GbiUUly0ANVg8jBC7xP9Bl79Z8zM='
				allowed_ips:          ['10.1.2.0/24', '100.64.1.2/32']
			},
		]
	}
	mut znet_workload := network.to_workload(name: network_name, description: 'test_network1')

	zmachine := models.Zmachine{
		flist:            'https://hub.grid.tf/tf-official-apps/threefoldtech-ubuntu-22.04.flist'
		network:          models.ZmachineNetwork{
			public_ip:  ''
			interfaces: [
				models.ZNetworkInterface{
					network: network_name
					ip:      '10.1.1.3'
				},
			]
			planetary:  true
		}
		entrypoint:       '/sbin/zinit init'
		compute_capacity: models.ComputeCapacity{
			cpu:    1
			memory: i64(1024) * 1024 * 1024 * 2
		}
		env:              {
			'SSH_KEY': 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDTwULSsUubOq3VPWL6cdrDvexDmjfznGydFPyaNcn7gAL9lRxwFbCDPMj7MbhNSpxxHV2+/iJPQOTVJu4oc1N7bPP3gBCnF51rPrhTpGCt5pBbTzeyNweanhedkKDsCO2mIEh/92Od5Hg512dX4j7Zw6ipRWYSaepapfyoRnNSriW/s3DH/uewezVtL5EuypMdfNngV/u2KZYWoeiwhrY/yEUykQVUwDysW/xUJNP5o+KSTAvNSJatr3FbuCFuCjBSvageOLHePTeUwu6qjqe+Xs4piF1ByO/6cOJ8bt5Vcx0bAtI8/MPApplUU/JWevsPNApvnA/ntffI+u8DCwgP'
		}
	}
	mut zmachine_workload := zmachine.to_workload(name: 'vm2', description: 'zmachine_test')

	signature_requirement := models.SignatureRequirement{
		weight_required: 1
		requests:        [
			models.SignatureRequest{
				twin_id: deployer.twin_id
				weight:  1
			},
		]
	}

	mut deployment := models.new_deployment(
		twin_id:               deployer.twin_id
		description:           'test deployment'
		workloads:             [znet_workload, zmachine_workload]
		signature_requirement: signature_requirement
	)
	deployment.add_metadata('vm', 'SimpleVM')

	contract_id := deployer.deploy(node_id, mut deployment, deployment.metadata, 0) or {
		logger.error('failed to deploy deployment: ${err}')
		exit(1)
	}
	logger.info('deployment contract id: ${contract_id}')
	dl := deployer.get_deployment(contract_id, node_id) or {
		logger.error('failed to get deployment data: ${err}')
		exit(1)
	}

	machine_res := get_machine_result(dl)!
	logger.info('zmachine result: ${machine_res}')
}

fn get_machine_result(dl models.Deployment) !models.ZmachineResult {
	for _, w in dl.workloads {
		if w.type_ == models.workload_types.zmachine {
			res := json.decode(models.ZmachineResult, w.result.data)!
			return res
		}
	}

	return error('failed to get zmachine workload')
}
