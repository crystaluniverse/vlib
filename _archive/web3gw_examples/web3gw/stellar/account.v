module main

import freeflowuniverse.crystallib.data.rpcwebsocket { RpcWsClient }
import freeflowuniverse.crystallib.threefold.web3gw.stellar
import flag
import log
import os

const default_server_address = 'ws://127.0.0.1:8080'

fn execute_rpcs(mut client RpcWsClient, mut logger log.Logger, secret string, network string, account string) ! {
	mut stellar_client := stellar.new(mut client)

	stellar_client.load(secret: secret, network: network)!

	// empty string to account_data results in account data of loaded key
	account_data := stellar_client.account_data(account)!
	logger.info('Account data: ${account_data}')
}

fn main() {
	mut fp := flag.new_flag_parser(os.args)
	fp.application('Welcome to the web3_proxy client. The web3_proxy client allows you to execute all remote procedure calls that the web3_proxy server can handle.')
	fp.limit_free_args(0, 0)!
	fp.description('')
	fp.skip_executable()
	address := fp.string('address', `a`, '${default_server_address}', 'The address of the web3_proxy server to connect to.')
	secret := fp.string('secret', `s`, '', 'The secret of your stellar key')
	account := fp.string('account', `d`, '', 'The account to ask the account data of, if empty the account of the secret will be used')
	network := fp.string('network', `n`, 'public', 'The network to connect to. Should be testnet or public.')
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

	execute_rpcs(mut myclient, mut logger, secret, network, account) or {
		logger.error('Failed executing calls: ${err}')
		exit(1)
	}
}
