#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.threefold.gridproxy
import freeflowuniverse.crystallib.ui.console

mut gp_client := gridproxy.new(net: .test, cache: true)!

// get twin list
twins := gp_client.get_twins()!
console.print_debug('${twins}')

// get farm list
farms := gp_client.get_farms()!
console.print_debug('${farms}')

// get node list
nodes := gp_client.get_nodes()!
console.print_debug('${nodes}')

// get gateway list
gateways := gp_client.get_gateways()!
console.print_debug('${gateways}')

// get contract list
contracts := gp_client.get_contracts()!
console.print_debug('${contracts}')

// get grid stats
stats := gp_client.get_stats()!
console.print_debug('${stats}')
