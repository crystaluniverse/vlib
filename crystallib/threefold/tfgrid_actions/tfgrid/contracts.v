module tfgrid

import freeflowuniverse.crystallib.core.playbook { Action }
import freeflowuniverse.crystallib.threefold.web3gw.tfgrid as tfgrid_client { ContractFilter, FindContracts, Limit }

pub fn (mut h TFGridHandler) contracts(action Action) ! {
	match action.name {
		'get' {
			mnemonics := action.params.get_default('mnemonics', '')!
			network := action.params.get_default('network', 'main')!
			h.tfgrid.load(
				mnemonic: mnemonics
				network:  network
			)!
			mut filter := ContractFilter{}
			if action.params.exists('contract_id') {
				filter.contract_id = action.params.get_u64('contract_id')!
			}
			if action.params.exists('twin_id') {
				filter.twin_id = action.params.get_u64('twin_id')!
			}
			if action.params.exists('node_id') {
				filter.node_id = action.params.get_u64('node_id')!
			}
			if action.params.exists('type') {
				filter.type_ = action.params.get('type')!
			}
			if action.params.exists('state') {
				filter.state = action.params.get('state')!
			}
			if action.params.exists('name') {
				filter.name = action.params.get('name')!
			}
			if action.params.exists('number_of_public_ips') {
				filter.number_of_public_ips = action.params.get_u64('number_of_public_ips')!
			}
			if action.params.exists('deployment_data') {
				filter.deployment_data = action.params.get('deployment_data')!
			}
			if action.params.exists('deployment_hash') {
				filter.deployment_hash = action.params.get('deployment_hash')!
			}

			page := action.params.get_u64_default('page', 1)!
			size := action.params.get_u64_default('size', 50)!
			randomize := action.params.get_default_false('randomize')

			req := FindContracts{
				filters:    filter
				pagination: Limit{
					page:      page
					size:      size
					randomize: randomize
				}
			}

			res := h.tfgrid.find_contracts(req)!
			h.logger.info('contracts: ${res}')
		}
		else {
			return error('explorer does not support operation: ${action.name}')
		}
	}
}
