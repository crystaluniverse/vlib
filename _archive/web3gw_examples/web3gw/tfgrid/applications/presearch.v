module main

import freeflowuniverse.crystallib.threefold.web3gw.tfgrid { TFGridClient }
import freeflowuniverse.crystallib.threefold.web3gw.tfgrid.applications.presearch { PresearchResult }
import log { Logger }
import flag { FlagParser }
import os
import freeflowuniverse.crystallib.data.rpcwebsocket

const default_server_address = 'ws://127.0.0.1:8080'

fn deploy_presearch(mut fp FlagParser, mut t TFGridClient) !PresearchResult {
	fp.usage_example('deploy [options]')

	name := fp.string_opt('name', `n`, 'Name of the gateway instance')!
	farm_id := fp.int('farm_id', `f`, 0, 'Farm ID to deploy on')
	ssh_key := fp.string('ssh', `s`, '', 'Public SSH Key to access the instance')
	disk_size := fp.int('disk_size', `d`, 0, 'Size of disk mounted on the presearch instance')
	public_ipv4 := fp.bool('public_ipv4', `i`, false, 'True to add public ipv4 to presearch instance')
	registration_code := fp.string_opt('registration_code', `r`, 'You need to sign up on Presearch in order to get your Presearch Registration Code.')!
	public_restore_key := fp.string('public_restore_key', `p`, '', 'presearch public key for restoring old nodes')
	private_restore_key := fp.string('private_restore_key', `k`, '', 'presearch private key for restoring old nodes')
	_ := fp.finalize()!

	mut presearch_client := t.applications().presearch()
	return presearch_client.deploy(
		name:                name
		farm_id:             u64(farm_id)
		ssh_key:             ssh_key
		disk_size:           u32(disk_size)
		public_ipv4:         public_ipv4
		registration_code:   registration_code
		public_restore_key:  public_restore_key
		private_restore_key: private_restore_key
	)!
}

fn get_presearch(mut fp FlagParser, mut t TFGridClient) !PresearchResult {
	fp.usage_example('get [options]')

	name := fp.string_opt('name', `n`, 'Name of the clusetr')!
	_ := fp.finalize()!

	mut presearch_client := t.applications().presearch()
	return presearch_client.get(name)!
}

fn delete_presearch(mut fp FlagParser, mut t TFGridClient) ! {
	fp.usage_example('delete [options]')

	name := fp.string_opt('name', `n`, 'Name of the cluster')!
	_ := fp.finalize()!

	mut presearch_client := t.applications().presearch()
	return presearch_client.delete(name)
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

	tfgrid_client.load(tfgrid.Credentials{
		mnemonic: mnemonic
		network:  network
	})!

	match operation {
		'deploy' {
			mut new_fp := flag.new_flag_parser(remainig_args)
			res := deploy_presearch(mut new_fp, mut tfgrid_client) or {
				logger.error('${err}')
				exit(1)
			}
			logger.info('${res}')
		}
		'get' {
			mut new_fp := flag.new_flag_parser(remainig_args)
			res := get_presearch(mut new_fp, mut tfgrid_client) or {
				logger.error('${err}')
				exit(1)
			}
			logger.info('${res}')
		}
		'delete' {
			mut new_fp := flag.new_flag_parser(remainig_args)
			delete_presearch(mut new_fp, mut tfgrid_client) or {
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
