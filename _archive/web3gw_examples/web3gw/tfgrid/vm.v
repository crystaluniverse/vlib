module main

import freeflowuniverse.crystallib.threefold.web3gw.tfgrid { DeployVM, NetworkDeployment, TFGridClient, VMDeployment }
import log { Logger }
import flag { FlagParser }
import os
import freeflowuniverse.crystallib.data.rpcwebsocket
import rand

const default_server_address = 'ws://127.0.0.1:8080'

fn deploy_vm(mut fp FlagParser, mut t TFGridClient) !VMDeployment {
	fp.usage_example('deploy [options]')

	name := fp.string('vm_name', `m`, rand.string(6), 'VM name')
	farm_id := fp.int('farm_id', `f`, 0, 'Farm ID to deploy on')
	disk_size := fp.int('disk_size', `d`, 0, 'Size of disk the will be mounted on each vm')
	gateway := fp.bool('gateway', `g`, false, 'True to add a gateway for each vm')
	wg := fp.bool('wg', `w`, false, 'True to add a wireguard access point to the network')
	_ := fp.finalize()!

	vm := DeployVM{
		name:                 name
		farm_id:              u32(farm_id)
		rootfs_size:          u64(disk_size)
		gateway:              gateway
		add_wireguard_access: wg
	}

	return t.deploy_vm(vm)!
}

fn get_vm(mut fp FlagParser, mut t TFGridClient) !VMDeployment {
	fp.usage_example('get [options]')

	vm := fp.string_opt('vm_name', `v`, 'Name of the VM')!
	_ := fp.finalize()!

	return t.get_vm_deployment(vm)!
}

fn delete_vm(mut fp FlagParser, mut t TFGridClient) ! {
	fp.usage_example('delete [options]')

	vm_name := fp.string_opt('vm_name', `v`, 'Name of the VM to be deleted')!

	_ := fp.finalize()!

	t.cancel_vm_deployment(vm_name)!
}

fn remove_vm(mut fp FlagParser, mut t TFGridClient) !NetworkDeployment {
	fp.usage_example('remove [options]')

	vm_name := fp.string_opt('vm_name', `v`, 'Name of the VM to be removed')!
	network := fp.string_opt('vm_network', `v`, 'Name of the VM network')!

	_ := fp.finalize()!

	return t.remove_vm_from_network_deployment(
		network: network
		vm:      vm_name
	)!
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
			res := deploy_vm(mut new_fp, mut tfgrid_client) or {
				logger.error('${err}')
				exit(1)
			}
			logger.info('${res}')
		}
		'get' {
			mut new_fp := flag.new_flag_parser(remainig_args)
			res := get_vm(mut new_fp, mut tfgrid_client) or {
				logger.error('${err}')
				exit(1)
			}
			logger.info('${res}')
		}
		'delete' {
			mut new_fp := flag.new_flag_parser(remainig_args)
			delete_vm(mut new_fp, mut tfgrid_client) or {
				logger.error('${err}')
				exit(1)
			}
		}
		'remove' {
			mut new_fp := flag.new_flag_parser(remainig_args)
			res := remove_vm(mut new_fp, mut tfgrid_client) or {
				logger.error('${err}')
				exit(1)
			}
			logger.info('${res}')
		}
		else {
			logger.error('operation ${operation} is invalid')
			exit(1)
		}
	}
}
