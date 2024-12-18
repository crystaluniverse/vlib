module tfgrid_actions

import log
import freeflowuniverse.crystallib.core.playbook
import freeflowuniverse.crystallib.data.rpcwebsocket { RpcWsClient }
import freeflowuniverse.crystallib.threefold.web3gw.tfgrid as tfgrid_client
import freeflowuniverse.crystallib.threefold.web3gw.tfchain as tfchain_client
import freeflowuniverse.crystallib.threefold.web3gw.stellar as stellar_client
import freeflowuniverse.crystallib.threefold.web3gw.eth as eth_client
import freeflowuniverse.crystallib.threefold.web3gw.btc as btc_client
import freeflowuniverse.crystallib.threefold.tfgrid_actions.tfgrid { TFGridHandler }
import freeflowuniverse.crystallib.threefold.tfgrid_actions.web3gw { Web3GWHandler }
import freeflowuniverse.crystallib.threefold.tfgrid_actions.clients { Clients }
import freeflowuniverse.crystallib.threefold.tfgrid_actions.stellar { StellarHandler }

const tfgrid_book = 'tfgrid'
const web3gw_book = 'web3gw'
const stellar_book = 'stellar'

pub struct Runner {
pub mut:
	path            string
	clients         Clients
	tfgrid_handler  TFGridHandler
	web3gw_handler  Web3GWHandler
	stellar_handler StellarHandler
}

@[params]
pub struct RunnerArgs {
pub mut:
	name    string
	path    string
	address string
}

pub fn new(args RunnerArgs, debug_log bool) !Runner {
	mut ap := playbook.new(path: args.path)!

	mut logger := log.Logger(&log.Log{
		level: if debug_log { .debug } else { .info }
	})

	mut rpc_client := rpcwebsocket.new_rpcwsclient(args.address, &logger) or {
		return error('Failed creating rpc websocket client: ${err}')
	}
	_ := spawn rpc_client.run()

	mut gw_clients := get_clients(mut rpc_client)!

	tfgrid_handler := tfgrid.new(mut rpc_client, logger, mut gw_clients.tfg_client)
	web3gw_handler := web3gw.new(mut rpc_client, &logger, mut gw_clients)
	stellar_handler := stellar.new(mut rpc_client, &logger, mut gw_clients.str_client)

	mut runner := Runner{
		path:            args.path
		tfgrid_handler:  tfgrid_handler
		web3gw_handler:  web3gw_handler
		clients:         gw_clients
		stellar_handler: stellar_handler
	}

	runner.run(mut ap)!
	return runner
}

pub fn (mut r Runner) run(mut acs playbook.Actions) ! {
	for action in acs.actions {
		match action.book {
			threelang.tfgrid_book {
				r.tfgrid_handler.handle_action(action)!
			}
			threelang.web3gw_book {
				r.web3gw_handler.handle_action(action)!
			}
			threelang.stellar_book {
				r.stellar_handler.handle_action(action)!
			}
			else {
				return error('module ${action.book} is invalid')
			}
		}
	}
}

pub fn get_clients(mut rpc_client RpcWsClient) !Clients {
	return Clients{
		tfg_client: tfgrid_client.new(mut rpc_client)
		tfc_client: tfchain_client.new(mut rpc_client)
		btc_client: btc_client.new(mut rpc_client)
		eth_client: eth_client.new(mut rpc_client)
		str_client: stellar_client.new(mut rpc_client)
	}
}
