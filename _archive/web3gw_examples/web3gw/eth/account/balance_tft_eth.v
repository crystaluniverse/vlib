module main

import freeflowuniverse.crystallib.data.rpcwebsocket { RpcWsClient }
import freeflowuniverse.crystallib.threefold.web3gw.eth
import flag
import log
import os

const default_server_address = 'ws://127.0.0.1:8080'
const goerli_node_url = 'ws://45.156.243.137:8546'

fn execute_rpcs(mut client RpcWsClient, mut logger log.Logger, secret string, eth_url string) ! {
	mut eth_client := eth.new(mut client)
	eth_client.load(url: eth_url, secret: secret)!

	address := eth_client.address()!
	logger.info('address: ${address}\n')

	balance := eth_client.tft_balance()!
	logger.info('tft balance: ${balance}')
}

fn main() {
	mut fp := flag.new_flag_parser(os.args)
	fp.application('Welcome to the web3_proxy client. The web3_proxy client allows you to execute all remote procedure calls that the web3_proxy server can handle.')
	fp.limit_free_args(0, 0)!
	fp.description('')
	fp.skip_executable()
	secret := fp.string('secret', `s`, '', 'The secret to use for eth.')
	// eth_url defaults to Goerli node
	eth_url := fp.string('eth', `e`, '${goerli_node_url}', 'The url of the ethereum node to connect to.')
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

	execute_rpcs(mut myclient, mut logger, secret, eth_url) or {
		logger.error('Failed executing calls: ${err}')
		exit(1)
	}
}
