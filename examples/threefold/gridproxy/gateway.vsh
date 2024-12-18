#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.threefold.gridproxy
import freeflowuniverse.crystallib.ui.console

fn get_gateway_nodes_example() ! {
	mut myfilter := gridproxy.nodefilter()!

	myfilter.status = 'up'

	mut gp_client := gridproxy.new(net: .dev, cache: true)!
	mygateways := gp_client.get_gateways(myfilter)!

	console.print_debug('${mygateways}')
	console.print_debug('${mygateways.len}')
}

fn get_gateway_by_id_example(node_id u64) ! {
	mut myfilter := gridproxy.nodefilter()!

	myfilter.node_id = node_id

	mut gp_client := gridproxy.new(net: .dev, cache: true)!
	mygateways := gp_client.get_gateways(myfilter)!

	console.print_debug('${mygateways}')
}

get_gateway_nodes_example()!
get_gateway_by_id_example(u64(11))!
