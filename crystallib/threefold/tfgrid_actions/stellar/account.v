module stellar

import freeflowuniverse.crystallib.core.playbook { Action }

fn (mut h StellarHandler) account(action Action) ! {
	match action.name {
		'address' {
			res := h.client.address()!

			h.logger.info(res)
		}
		'create' {
			network := action.params.get_default('network', 'public')!

			res := h.client.create_account(network)!

			h.logger.info(res)
		}
		'transactions' {
			account := action.params.get_default('account', '')!
			limit := action.params.get_u32_default('limit', 10)!
			include_failed := action.params.get_default_false('include_failed')
			cursor := action.params.get_default('cursor', '')!
			ascending := action.params.get_default_false('ascending')

			res := h.client.transactions(
				account:        account
				limit:          limit
				include_failed: include_failed
				cursor:         cursor
				ascending:      ascending
			)!

			h.logger.info('Transactions: ${res}')
		}
		'data' {
			account := action.params.get('account')!

			res := h.client.account_data(account)!

			h.logger.info('${res}')
		}
		else {
			return error('account action ${action.name} is invalid')
		}
	}
}
