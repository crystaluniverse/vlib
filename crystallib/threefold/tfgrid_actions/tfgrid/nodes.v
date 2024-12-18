module tfgrid

import freeflowuniverse.crystallib.core.playbook { Action }
import freeflowuniverse.crystallib.threefold.web3gw.tfgrid { FindNodes, Limit, NodeFilter }

pub fn (mut h TFGridHandler) nodes(action Action) ! {
	match action.name {
		'get' {
			// network := action.params.get_default('network', 'main')!
			// h.tfgrid.load(network)!

			mut filter := NodeFilter{}
			if action.params.exists('status') {
				filter.status = action.params.get('status')!
			}
			if action.params.exists('free_mru') {
				filter.free_mru = action.params.get_storagecapacity_in_bytes('free_mru')!
			}
			if action.params.exists('free_hru') {
				filter.free_hru = action.params.get_storagecapacity_in_bytes('free_hru')!
			}
			if action.params.exists('free_sru') {
				filter.free_sru = action.params.get_storagecapacity_in_bytes('free_sru')!
			}
			if action.params.exists('total_mru') {
				filter.total_mru = action.params.get_storagecapacity_in_bytes('total_mru')!
			}
			if action.params.exists('total_hru') {
				filter.total_hru = action.params.get_storagecapacity_in_bytes('total_hru')!
			}
			if action.params.exists('total_sru') {
				filter.total_sru = action.params.get_storagecapacity_in_bytes('total_sru')!
			}
			if action.params.exists('total_cru') {
				filter.total_cru = action.params.get_u64('total_cru')!
			}
			if action.params.exists('country') {
				filter.country = action.params.get('country')!
			}
			if action.params.exists('country_contains') {
				filter.country_contains = action.params.get('country_contains')!
			}
			if action.params.exists('city') {
				filter.city = action.params.get('city')!
			}
			if action.params.exists('city_contains') {
				filter.city_contains = action.params.get('city_contains')!
			}
			if action.params.exists('farm_name') {
				filter.farm_name = action.params.get('farm_name')!
			}
			if action.params.exists('farm_name_contains') {
				filter.farm_name_contains = action.params.get('farm_name_contains')!
			}
			if action.params.exists('farm_id') {
				filter.farm_ids = action.params.get_list_u64('farm_id')!
			}
			if action.params.exists('free_ips') {
				filter.free_ips = action.params.get_u64('free_ips')!
			}
			if action.params.exists('ipv4') {
				filter.ipv4 = action.params.get_default_false('ipv4')
			}
			if action.params.exists('ipv6') {
				filter.ipv6 = action.params.get_default_false('ipv6')
			}
			if action.params.exists('domain') {
				filter.domain = action.params.get_default_false('domain')
			}
			if action.params.exists('dedicated') {
				filter.dedicated = action.params.get_default_false('dedicated')
			}
			if action.params.exists('rentable') {
				filter.rentable = action.params.get_default_false('rentable')
			}
			if action.params.exists('rented') {
				filter.rented = action.params.get_default_false('rented')
			}
			if action.params.exists('rented_by') {
				filter.rented_by = action.params.get_u64('rented_by')!
			}
			if action.params.exists('available_for') {
				filter.available_for = action.params.get_u64('available_for')!
			}
			if action.params.exists('node_id') {
				filter.node_id = action.params.get_u64('node_id')!
			}
			if action.params.exists('twin_id') {
				filter.twin_id = action.params.get_u64('twin_id')!
			}

			page := action.params.get_u64_default('page', 1)!
			size := action.params.get_u64_default('size', 50)!
			randomize := action.params.get_default_false('randomize')

			req := FindNodes{
				filters:    filter
				pagination: Limit{
					page:      page
					size:      size
					randomize: randomize
				}
			}

			res := h.tfgrid.find_nodes(req)!
			h.logger.info('nodes: ${res}')
		}
		else {
			return error('explorer does not support operation: ${action.name}')
		}
	}
}
