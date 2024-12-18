#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.threefold.grid as tfgrid
import freeflowuniverse.crystallib.threefold.grid.models
import log

fn main() {
	mut logger := &log.Log{}
	logger.set_level(.debug)

	mnemonics := tfgrid.get_mnemonics() or {
		logger.error(err.str())
		exit(1)
	}
	chain_network := tfgrid.ChainNetwork.dev // User your desired network
	mut deployer := tfgrid.new_deployer(mnemonics, chain_network, mut logger)!

	gw := models.GatewayNameProxy{
		tls_passthrough: false
		backends:        ['http://1.1.1.1']
		name:            'hamada_gw'
	}

	wl := gw.to_workload(name: 'hamada_gw')

	name_contract_id := deployer.client.create_name_contract(wl.name)!
	logger.info('name contract ${wl.name} created with id ${name_contract_id}')

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
		workloads:             [wl]
		signature_requirement: signature_requirement
	)

	node_id := u32(14)
	node_contract_id := deployer.deploy(node_id, mut deployment, '', 0)!
	logger.info('node contract created with id ${node_contract_id}')
}
