module main

import freeflowuniverse.crystallib.data.rpcwebsocket { RpcWsClient }
import freeflowuniverse.crystallib.threefold.web3gw.stellar
import flag
import log
import os

const default_server_address = 'ws://127.0.0.1:8080'

fn execute_rpcs(mut client RpcWsClient, mut logger log.Logger, secret string, network string, source string, destination string, amount string) ! {
	mut stellar_client := stellar.new(mut client)

	stellar_client.load(secret: secret, network: network)!

	account := stellar_client.address()!

	mut balance := stellar_client.balance(address: account)!
	logger.info('Balance: ${balance}')

	stellar_client.swap(amount: amount, source_asset: source, destination_asset: destination)!

	balance = stellar_client.balance(address: account)!
	logger.info('Balance: ${balance}')
}

fn main() {
	mut fp := flag.new_flag_parser(os.args)
	fp.application('Welcome to the web3_proxy client. The web3_proxy client allows you to execute all remote procedure calls that the web3_proxy server can handle.')
	fp.limit_free_args(0, 0)!
	fp.description('')
	fp.skip_executable()
	address := fp.string('address', `d`, '${default_server_address}', 'The address of the web3_proxy server to connect to.')
	secret := fp.string('secret', `s`, '', 'The secret of your stellar key')
	network := fp.string('network', `n`, 'public', 'The network to connect to. Should be testnet or public.')
	source := fp.string('source', `o`, 'xlm', 'The source asset to transfer tokens from')
	destination := fp.string('destination', `d`, 'tft', 'The destination asset to transfer tokens from')
	amount := fp.string('amount', `a`, '100.0', 'The amount to tranfser')
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

	execute_rpcs(mut myclient, mut logger, secret, network, source, destination, amount) or {
		logger.error('Failed executing calls: ${err}')
		exit(1)
	}
}
