#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.threefold.gridproxy
import freeflowuniverse.crystallib.ui.console

fn get_nodes_example() ! {
	mut myfilter := gridproxy.nodefilter()!

	myfilter.status = 'up'
	myfilter.country = 'belgium'

	mut gp_client := gridproxy.new(net: .main, cache: true)!
	mynodes := gp_client.get_nodes(myfilter)!

	console.print_debug('${mynodes}')
}

fn get_node_by_id_example(node_id u64) ! {
	mut myfilter := gridproxy.nodefilter()!

	myfilter.node_id = node_id

	mut gp_client := gridproxy.new(net: .dev, cache: true)!
	mynodes := gp_client.get_nodes(myfilter)!

	console.print_debug('${mynodes}')

	// get node available resources
	node_available_resources := mynodes[0].calc_available_resources()
	console.print_debug('${node_available_resources}')
}

fn get_node_stats_by_id_example(node_id u64) ! {
	mut gp_client := gridproxy.new(net: .dev, cache: true)!

	node_stats := gp_client.get_node_stats_by_id(node_id)!

	console.print_debug('${node_stats}')
}

fn get_node_by_available_capacity_example() ! {
	mut myfilter := gridproxy.nodefilter()!

	// minimum free capacity
	myfilter.free_mru = u64(0)
	myfilter.free_sru = u64(1024) // 1 tb
	myfilter.free_hru = u64(0)
	myfilter.free_ips = u64(1)

	// init gridproxy client on devnet with redis cash
	mut gp_client := gridproxy.new(net: .dev, cache: true)!
	mynodes := gp_client.get_nodes(myfilter)!

	console.print_debug('${mynodes}')
}

fn get_node_by_city_country_example() ! {
	mut myfilter := gridproxy.nodefilter()!

	myfilter.city = 'Rio de Janeiro'
	myfilter.country = 'Brazil'

	mut gp_client := gridproxy.new(net: .main, cache: false)!
	mynodes := gp_client.get_nodes(myfilter)!

	console.print_debug('${mynodes}')
}

fn get_node_box_poc_example() ! {
	mut myfilter := gridproxy.nodefilter()!

	myfilter.status = 'up'

	mut gp_client := gridproxy.new(net: .main, cache: true)!
	mynodes := gp_client.get_nodes(myfilter)!

	for node in mynodes {
		console.print_debug('${node}')
		console.print_debug('${node.capacity.total_resources.hru.to_gigabytes()}')

		node_available_resources := node.calc_available_resources()
		console.print_debug('${node_available_resources}')

		node_stats := gp_client.get_node_stats_by_id(node.node_id)!
		console.print_debug('${node_stats}')
	}
}

get_nodes_example()!
get_node_by_id_example(u64(11))!
get_node_stats_by_id_example(u64(11))!
get_node_by_available_capacity_example()!
get_node_by_city_country_example()!
get_node_box_poc_example()!
