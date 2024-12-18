module main

import freeflowuniverse.crystallib.threefold.web3gw.tfgrid { TFGridClient, ZDBDeployment }
import log { Logger }
import flag { FlagParser }
import os
import freeflowuniverse.crystallib.data.rpcwebsocket
import rand

const default_server_address = 'ws://127.0.0.1:8080'

fn deploy_zdb(mut fp FlagParser, mut t TFGridClient) !ZDBDeployment {
	fp.usage_example('deploy [options]')

	name := fp.string('name', `z`, rand.string(6), 'zdb name')
	node_id := fp.int('node_id', `i`, 0, 'Node ID to deploy on')
	password := fp.string('password', `w`, '', 'Password for the ZDB')
	public := fp.bool('public', `p`, false, 'True to make ZDB public')
	size := fp.int('size', `s`, 10, 'Size in GB of the ZDB')
	mode := fp.string('mode', `d`, 'user', 'Mode of the ZDB')
	_ := fp.finalize()!

	zdb := ZDBDeployment{
		node_id:  u32(node_id)
		name:     name
		password: password
		public:   public
		size:     u32(size)
		mode:     mode
	}

	return t.deploy_zdb(zdb)!
}

fn get_zdb(mut fp FlagParser, mut t TFGridClient) !ZDBDeployment {
	fp.usage_example('get [options]')

	name := fp.string_opt('name', `z`, 'Name of the ZDB')!
	_ := fp.finalize()!

	return t.get_zdb_deployment(name)!
}

fn delete_zdb(mut fp FlagParser, mut t TFGridClient) ! {
	fp.usage_example('delete [options]')

	name := fp.string_opt('name', `v`, 'Name of the ZDB')!
	_ := fp.finalize()!

	return t.cancel_zdb_deployment(name)
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
	operation := fp.string_opt('operation', `o`, 'Required operation to perform ')!
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
			res := deploy_zdb(mut new_fp, mut tfgrid_client) or {
				logger.error('${err}')
				exit(1)
			}
			logger.info('${res}')
		}
		'get' {
			mut new_fp := flag.new_flag_parser(remainig_args)
			res := get_zdb(mut new_fp, mut tfgrid_client) or {
				logger.error('${err}')
				exit(1)
			}
			logger.info('${res}')
		}
		'delete' {
			mut new_fp := flag.new_flag_parser(remainig_args)
			delete_zdb(mut new_fp, mut tfgrid_client) or {
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
