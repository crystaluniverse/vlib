module tfgrid

import freeflowuniverse.crystallib.core.playbook { Action }
import freeflowuniverse.crystallib.threefold.web3gw.tfgrid { FarmFilter, FindFarms, Limit }

pub fn (mut h TFGridHandler) farms(action Action) ! {
	match action.name {
		'get' {
			mut filter := FarmFilter{}
			if action.params.exists('free_ips') {
				filter.free_ips = action.params.get_u64('free_ips')!
			}
			if action.params.exists('total_ips') {
				filter.total_ips = action.params.get_u64('total_ips')!
			}
			if action.params.exists('stellar_address') {
				filter.stellar_address = action.params.get('stellar_address')!
			}
			if action.params.exists('pricing_policy_id') {
				filter.pricing_policy_id = action.params.get_u64('pricing_policy_id')!
			}
			if action.params.exists('farm_id') {
				filter.farm_id = action.params.get_u64('farm_id')!
			}
			if action.params.exists('twin_id') {
				filter.twin_id = action.params.get_u64('twin_id')!
			}
			if action.params.exists('name') {
				filter.name = action.params.get('name')!
			}
			if action.params.exists('name_contains') {
				filter.name_contains = action.params.get('name_contains')!
			}
			if action.params.exists('certification_type') {
				filter.certification_type = action.params.get('certification_type')!
			}
			if action.params.exists('dedicated') {
				filter.dedicated = action.params.get_default_false('dedicated')
			}

			page := action.params.get_u64_default('page', 1)!
			size := action.params.get_u64_default('size', 50)!
			randomize := action.params.get_default_false('randomize')

			req := FindFarms{
				filters:    filter
				pagination: Limit{
					page:      page
					size:      size
					randomize: randomize
				}
			}

			res := h.tfgrid.find_farms(req)!
			h.logger.info('farms: ${res}')
		}
		else {
			return error('explorer does not support operation: ${action.name}')
		}
	}
}
