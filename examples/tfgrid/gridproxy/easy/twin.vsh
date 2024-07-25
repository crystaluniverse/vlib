#!/usr/bin/env -S v -n -w -enable-globals run

import freeflowuniverse.crystallib.threefold.gridproxy
import freeflowuniverse.crystallib.threefold.gridproxy.model
import log

fn get_all_twins_example() ! {
	mut logger := &log.Log{}
	logger.set_level(.debug)
	mut gp_client := gridproxy.get(.dev, true)!
	all_twin := gp_client.get_twins(model.TwinFilter{})!
	logger.info('${all_twin}')
}

fn get_twins_with_filter_example() ! {
	mut logger := &log.Log{}
	logger.set_level(.debug)
	mut gp_client := gridproxy.get(.dev, true)!

	twin := gp_client.get_twins(twin_id: u64(800))!
	logger.info('${twin}')
}

fn get_twin_iterator_example() ! {
	mut logger := &log.Log{}
	logger.set_level(.debug)
	mut gp_client := gridproxy.get(.dev, true)!

	max_page_iteration := u64(5) // set maximum pages to iterate on

	mut twin_iterator := gp_client.get_twins_iterator(model.TwinFilter{})
	mut iterator_twins := []model.Twin{}
	for {
		if twin_iterator.filter.page is u64 && twin_iterator.filter.page >= max_page_iteration {
			break
		}

		iterator_twin := twin_iterator.next()
		if iterator_twin != none {
			iterator_twins << iterator_twin
		} else {
			break // if the page is empty the next function will return none
		}
	}
	logger.info('${iterator_twins}')
}

fn main() {
	get_all_twins_example()!
	get_twins_with_filter_example()!
	get_twin_iterator_example()!
}
