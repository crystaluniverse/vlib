#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.threefold.grid as tfgrid
import freeflowuniverse.crystallib.threefold.gridproxy
import freeflowuniverse.crystallib.ui.console

fn get_contracts_example() ! {
	mut myfilter := gridproxy.contractfilter()!

	myfilter.state = 'Created'
	myfilter.contract_type = 'node'
	myfilter.twin_id = u64(5191)

	mut gp_client := gridproxy.new(net: .dev, cache: true)!
	mycontracts := gp_client.get_contracts(myfilter)!

	console.print_debug('${mycontracts}')
}

fn get_contract_by_id_example(contract_id u64) ! {
	mut myfilter := gridproxy.contractfilter()!

	myfilter.contract_id = contract_id

	mut gp_client := gridproxy.new(net: .dev, cache: true)!
	mycontracts := gp_client.get_contracts(myfilter)!

	console.print_debug('${mycontracts}')
}

fn get_my_contracts_example() ! {
	mnemonics := tfgrid.get_mnemonics()!
	mut deployer := tfgrid.new_deployer(mnemonics, .dev)!

	mut myfilter := gridproxy.contractfilter()!

	myfilter.twin_id = u64(deployer.twin_id)
	myfilter.state = 'created'

	mut gp_client := gridproxy.new(net: .dev, cache: false)!
	mycontracts := gp_client.get_contracts(myfilter)!

	console.print_debug('${mycontracts}')
}

get_contracts_example()!
get_contract_by_id_example(u64(49268))!
get_my_contracts_example()!
