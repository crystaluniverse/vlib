module main

import freeflowuniverse.crystallib.data.rpcwebsocket { RpcWsClient }
import freeflowuniverse.crystallib.threefold.web3gw.eth
import freeflowuniverse.crystallib.threefold.web3gw.stellar
import flag
import log
import os

const default_server_address = 'ws://127.0.0.1:8080'
const mainnet_ethereum_node_url = 'ws://185.69.167.224:8546'

fn execute_rpcs(mut client RpcWsClient, mut logger log.Logger, secret string) ! {
	mut eth_client := eth.new(mut client)
	mut stellar_client := stellar.new(mut client)
	eth_client.load(url: mainnet_ethereum_node_url, secret: secret)!

	stellar_secret := eth_client.create_and_activate_stellar_account('public')!
	logger.info('Secret: ${stellar_secret} (keep it safe!!!)')

	stellar_client.load(network: 'public', secret: stellar_secret)!

	address := stellar_client.address()!
	logger.info('Address: ${address}')

	balance := stellar_client.balance(address)!
	logger.info('Balance: ${balance}')
}

fn main() {
	mut fp := flag.new_flag_parser(os.args)
	fp.application('This tool allows you to create a stellar account and activate it using ethereum (only on mainnet). It requires you to have an ethereum account and some assets on your account.')
	fp.limit_free_args(0, 0)!
	fp.description('')
	fp.skip_executable()
	secret := fp.string('secret', `s`, '', 'The secret to use for eth.')
	address := fp.string('address', `a`, '${default_server_address}', 'The address of the web3_proxy server to connect to.')
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

	execute_rpcs(mut myclient, mut logger, secret) or {
		logger.error('Failed executing calls: ${err}')
		exit(1)
	}
}
