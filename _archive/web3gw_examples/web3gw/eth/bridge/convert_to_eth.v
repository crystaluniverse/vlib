module main

import freeflowuniverse.crystallib.data.rpcwebsocket { RpcWsClient }
import freeflowuniverse.crystallib.threefold.web3gw.stellar
import flag
import log
import os

const default_server_address = 'ws://127.0.0.1:8080'

fn execute_rpcs(mut client RpcWsClient, mut logger log.Logger, secret string, network string, amount string, destination string) ! {
	mut stellar_client := stellar.new(mut client)

	stellar_client.load(secret: secret, network: network)!

	balance := stellar_client.balance('')! // fill in your address
	logger.info('Stellar tft balance: ${balance}\n')

	// Destination is the ethereum address
	stellar_client.bridge_to_eth(amount: amount, destination: destination)!
}

fn main() {
	mut fp := flag.new_flag_parser(os.args)
	fp.application('Welcome to the web3_proxy client. The web3_proxy client allows you to execute all remote procedure calls that the web3_proxy server can handle.')
	fp.limit_free_args(0, 0)!
	fp.description('')
	fp.skip_executable()
	address := fp.string('address', `a`, '${default_server_address}', 'The address of the web3_proxy server to connect to.')
	secret := fp.string('secret', `s`, '', 'The secret of your stellar key')
	network := fp.string('network', `n`, '', 'The network to connect to. Should be testnet or public.')

	amount := fp.string('amount', `m`, '', 'The amount of TFT to convert (can be with decimals: "0.1")')
	destination := fp.string('destination', `d`, '', 'The destination ethereum address')

	debug_log := fp.bool('debug', 0, false, 'By setting this flag the client will print debug logs too.')

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

	execute_rpcs(mut myclient, mut logger, secret, network, amount, destination) or {
		logger.error('Failed executing calls: ${err}')
		exit(1)
	}
}
