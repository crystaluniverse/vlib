module main

import freeflowuniverse.crystallib.threefold.web3gw.tfgrid { TFGridClient }
import freeflowuniverse.crystallib.threefold.web3gw.tfgrid.applications.discourse { DiscourseResult }
import log { Logger }
import flag { FlagParser }
import os
import freeflowuniverse.crystallib.data.rpcwebsocket

const default_server_address = 'ws://127.0.0.1:8080'

fn deploy_discourse(mut fp FlagParser, mut t TFGridClient) !DiscourseResult {
	fp.usage_example('deploy [options]')

	name := fp.string_opt('name', `n`, 'Name of the discourse instance')!
	farm_id := fp.int('farm_id', `f`, 0, 'Farm ID to deploy the instance on')
	capacity := fp.string('capacity', `c`, 'medium', 'Capacity of the discourse instance')
	disk_size := fp.int('disk', `d`, 0, 'Size in GB of disk to be mounted')
	ssh_key := fp.string('ssh', `k`, '', 'Public SSH key to access the discourse machine')
	developer_email := fp.string('dev_email', `e`, '', 'Developer email')
	smtp_address := fp.string('smtp_address', `a`, '', 'SMTP Address')
	smtp_username := fp.string('smtp_username', `u`, '', 'SMTP username')
	smtp_password := fp.string('smtp_password', `p`, '', 'SMTP password')
	smtp_enable_tls := fp.bool('smtp_enable_tls', `t`, false, 'True to enable TLS for SMTP')
	smtp_port := fp.int('smtp_port', `o`, 0, 'SMTP server port')
	public_ipv6 := fp.bool('public_ipv6', `i`, false, 'Add public ipv6 to the instance')
	_ := fp.finalize()!

	mut discourse_client := t.applications().discourse()
	return discourse_client.deploy(
		name:            name
		farm_id:         u32(farm_id)
		capacity:        capacity
		disk_size:       u32(disk_size)
		ssh_key:         ssh_key
		developer_email: developer_email
		smtp_address:    smtp_address
		smtp_username:   smtp_username
		smtp_password:   smtp_password
		smtp_enable_tls: smtp_enable_tls
		smtp_port:       u32(smtp_port)
		public_ipv6:     public_ipv6
	)!
}

fn get_discourse(mut fp FlagParser, mut t TFGridClient) !DiscourseResult {
	fp.usage_example('get [options]')

	name := fp.string_opt('name', `n`, 'Name of the discourse instance')!
	_ := fp.finalize()!

	mut discourse_client := t.applications().discourse()
	return discourse_client.get(name)!
}

fn delete_discourse(mut fp FlagParser, mut t TFGridClient) ! {
	fp.usage_example('delete [options]')

	name := fp.string_opt('name', `n`, 'Name of the discourse instance')!
	_ := fp.finalize()!
	mut discourse_client := t.applications().discourse()
	return discourse_client.delete(name)
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
	operation := fp.string_opt('operation', `o`, 'Required operation to perform on Discourse') or {
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

	tfgrid_client.load(tfgrid.Credentials{
		mnemonic: mnemonic
		network:  network
	})!

	match operation {
		'deploy' {
			mut new_fp := flag.new_flag_parser(remainig_args)
			res := deploy_discourse(mut new_fp, mut tfgrid_client) or {
				logger.error('${err}')
				exit(1)
			}
			logger.info('${res}')
		}
		'get' {
			mut new_fp := flag.new_flag_parser(remainig_args)
			res := get_discourse(mut new_fp, mut tfgrid_client) or {
				logger.error('${err}')
				exit(1)
			}
			logger.info('${res}')
		}
		'delete' {
			mut new_fp := flag.new_flag_parser(remainig_args)
			delete_discourse(mut new_fp, mut tfgrid_client) or {
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
