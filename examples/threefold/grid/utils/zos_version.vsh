#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.threefold.grid as tfgrid
import freeflowuniverse.crystallib.threefold.griddriver
import freeflowuniverse.crystallib.ui.console
import log

fn test_get_zos_version(node_id u32) ! {
	mut logger := &log.Log{}
	logger.set_level(.debug)
	mnemonics := tfgrid.get_mnemonics()!
	chain_network := tfgrid.ChainNetwork.dev // User your desired network
	mut deployer := tfgrid.new_deployer(mnemonics, chain_network, mut logger)!
	node_twin_id := deployer.client.get_node_twin(node_id)!
	zos_version := deployer.client.get_zos_version(node_twin_id)!
	deployer.logger.info('Zos version is: ${zos_version}')
}

fn main() {
	test_get_zos_version(u32(14)) or { println('error happened: ${err}') }
}
