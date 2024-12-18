module main

import freeflowuniverse.crystallib.threefold.web3gw.tfgrid { GatewayFQDN, TFGridClient }
import log { Logger }
import flag { FlagParser }
import os
import freeflowuniverse.crystallib.data.rpcwebsocket

const default_server_address = 'ws://127.0.0.1:8080'

fn deploy_gateway_fqdn(mut fp FlagParser, mut t TFGridClient) !GatewayFQDN {
	fp.usage_example('deploy [options]')

	name := fp.string_opt('name', `n`, 'Name of the gateway instance')!
	node_id := fp.int('node_id', `i`, 0, 'Node ID to deploy on')
	tls_passthrough := fp.bool('tls_passthrough', `t`, false, 'if false will terminate the certificates on the gateway, else will passthrough the request as is.')
	backend := fp.string_opt('backend', `b`, 'Backend of the gateway')!
	fqdn := fp.string_opt('fqdn', `f`, 'FQDN of the gateway')!
	_ := fp.finalize()!

	return t.deploy_gateway_fqdn(GatewayFQDN{
		name:            name
		node_id:         u32(node_id)
		tls_passthrough: tls_passthrough
		backends:        [backend]
		fqdn:            fqdn
	})!
}

fn get_gateway_fqdn(mut fp FlagParser, mut t TFGridClient) !GatewayFQDN {
	fp.usage_example('get [options]')

	name := fp.string_opt('name', `n`, 'Name of the gateway instance')!
	_ := fp.finalize()!

	return t.get_gateway_fqdn(name)!
}

fn delete_gateway_fqdn(mut fp FlagParser, mut t TFGridClient) ! {
	fp.usage_example('delete [options]')

	name := fp.string_opt('name', `n`, 'Name of the gateway instance')!
	_ := fp.finalize()!

	return t.cancel_gateway_fqdn(name)
}

fn main() {
	mut fp := flag.new_flag_parser(os.args)
	fp.application('Welcome to the web3_proxy client. The web3_proxy client allows you to execute all remote procedure calls that the web3_proxy server can handle.')
	fp.description('')
	fp.skip_executable()
	fp.allow_unknown_args()

	mnemonic := fp.string_opt('mnemonic', `m`, 'The mnemonic to be used to call any function') or {
		eprintln('${err}')
		exit(1)
	}
	network := fp.string('network', `n`, 'dev', 'TF network to use')
	address := fp.string('address', `a`, '${default_server_address}', 'The address of the web3_proxy server to connect to.')
	debug_log := fp.bool('debug', 0, false, 'By setting this flag the client will print debug logs too.')
	operation := fp.string_opt('operation', `o`, 'Required operation to perform on Gateway FQDN') or {
		eprintln('${err}')
		exit(1)
	}
	remainig_args := fp.finalize() or {
		eprintln('${err}')
		exit(1)
	}

	mut logger := Logger(&log.Log{
		level: if debug_log { .debug } else { .info }
	})

	mut myclient := rpcwebsocket.new_rpcwsclient(address, &logger) or {
		logger.error('Failed creating rpc websocket client: ${err}')
		exit(1)
	}

	_ := spawn myclient.run()

	mut tfgrid_client := tfgrid.new(mut myclient)

	tfgrid_client.load(tfgrid.Load{
		mnemonic: mnemonic
		network:  network
	})!

	match operation {
		'deploy' {
			mut new_fp := flag.new_flag_parser(remainig_args)
			res := deploy_gateway_fqdn(mut new_fp, mut tfgrid_client) or {
				logger.error('${err}')
				exit(1)
			}
			logger.info('${res}')
		}
		'get' {
			mut new_fp := flag.new_flag_parser(remainig_args)
			res := get_gateway_fqdn(mut new_fp, mut tfgrid_client) or {
				logger.error('${err}')
				exit(1)
			}
			logger.info('${res}')
		}
		'delete' {
			mut new_fp := flag.new_flag_parser(remainig_args)
			delete_gateway_fqdn(mut new_fp, mut tfgrid_client) or {
				logger.error('${err}')
				exit(1)
			}
		}
		else {
			logger.error('operation ${operation} is invalid')
			exit(1)
		}
	}
}
