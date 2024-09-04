#!/usr/bin/env -S v -n -w -enable-globals -cg run

import freeflowuniverse.crystallib.threefold.gridproxy
import freeflowuniverse.crystallib.ui.console

mut myfilter := gridproxy.nodefilter()!

myfilter.free_mru = u64(1)
myfilter.free_sru = u64(1)
myfilter.free_hru = u64(1)
myfilter.free_ips = u64(1)

mut gp_client := gridproxy.new(net:.main, cache:false)!
mynodes := gp_client.get_nodes(myfilter)!

console.print_debug("${mynodes}")
	
