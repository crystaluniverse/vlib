module main

import freeflowuniverse.crystallib.data.rpcwebsocket { RpcWsClient }
import freeflowuniverse.crystallib.threefold.web3gw.tfgrid
import flag
import log
import os

const default_server_address = 'http://127.0.0.1:8080'

@[params]
pub struct Arguments {
	network          string = 'main'
	deployment_name  string
	tfchain_mnemonic string
}

fn execute_rpcs(mut client RpcWsClient, mut logger log.Logger, args Arguments) ! {
	mut tfgrid_client := tfgrid.new(mut client)

	tfgrid_client.load(network: args.network, mnemonic: args.tfchain_mnemonic)!

	tfgrid_client.cancel_network_deployment(args.deployment_name)!
	logger.info('Canceled!')
}

fn main() {
	mut fp := flag.new_flag_parser(os.args)
	fp.application('This tool allows you to deploy a vm on mainnet using ethereum. It requires you to have a valid ethereum mainnet account, some funds on it and a tfchain account')
	fp.limit_free_args(0, 0)!
	fp.description('')
	fp.skip_executable()

	address := fp.string('address', `a`, '${default_server_address}', 'The address of the web3_proxy server to connect to.')
	debug_log := fp.bool('debug', 0, false, 'By setting this flag the client will print debug logs too.')

	tfchain_mnemonic := fp.string('tfchain-mnemonic', 0, '', 'The mnemonic of your tfchain account.')
	network := fp.string('network', 0, 'main', 'The tfchain network to connect to.')
	deployment_name := fp.string('name', 0, '', 'The name of the deployment to cancel.')

	_ := fp.finalize() or {
		eprintln(err)
		println(fp.usage())
		exit(1)
	}

	mut logger := log.Logger(&log.Log{
		level: if debug_log { .debug } else { .info }
	})

	mut myclient := rpcwebsocket.new_rpcwsclient(address, &logger) or {
		logger.error('Failed creating rpc websocket client: ${err}')
		exit(1)
	}

	_ := spawn myclient.run()

	arguments := Arguments{
		network:          network
		tfchain_mnemonic: tfchain_mnemonic
		deployment_name:  deployment_name
	}

	execute_rpcs(mut myclient, mut logger, arguments) or {
		logger.error('Failed executing calls: ${err}')
		exit(1)
	}
}
