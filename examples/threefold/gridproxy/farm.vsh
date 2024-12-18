#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.threefold.gridproxy
import freeflowuniverse.crystallib.ui.console

fn get_farms_example() ! {
	mut myfilter := gridproxy.farmfilter()!

	myfilter.country = 'Egypt'
	myfilter.total_ips = u64(10)

	mut gp_client := gridproxy.new(net: .dev, cache: true)!
	myfarms := gp_client.get_farms(myfilter)!

	console.print_debug('${myfarms}')
}

fn get_farm_by_name_example(farm_name string) ! {
	mut myfilter := gridproxy.farmfilter()!

	myfilter.name = farm_name

	mut gp_client := gridproxy.new(net: .main, cache: true)!
	myfarms := gp_client.get_farms(myfilter)!

	console.print_debug('${myfarms}')
}

get_farms_example()!
get_farm_by_name_example('freefarm')!
