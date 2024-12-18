module main

import freeflowuniverse.crystallib.data.rpcwebsocket { RpcWsClient }
import freeflowuniverse.crystallib.threefold.web3gw.ipfs
import flag
import log
import os
import encoding.base64

const default_server_address = 'ws://127.0.0.1:8080'

fn execute_rpcs(mut client RpcWsClient, mut logger log.Logger) ! {
	mut ipfs_client := ipfs.new(mut client)
	// ipfs_client.load(url:'', secret: secret)!

	cid := ipfs_client.store_file('sometext'.bytes())!
	logger.info('cid: ${cid}')

	content := ipfs_client.get_file(cid)!
	logger.info('content: ${base64.decode_str(content)}')

	cids := ipfs_client.list_cids()!
	logger.info('cids: ${cids}')

	removed := ipfs_client.remove_file(cid)!
	logger.info('removed file?: ${removed}')

	ipfs_client.remove_all_files()!
	logger.info('example how to remove all files')
}

fn main() {
	mut fp := flag.new_flag_parser(os.args)
	fp.application('Welcome to the web3_proxy client. The web3_proxy client allows you to execute all remote procedure calls that the web3_proxy server can handle.')
	fp.limit_free_args(0, 0)!
	fp.description('')
	fp.skip_executable()
	// secret := fp.string('secret', `s`, '', 'The secret to use for ipf.')
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

	execute_rpcs(mut myclient, mut logger) or {
		logger.error('Failed executing calls: ${err}')
		exit(1)
	}
}
