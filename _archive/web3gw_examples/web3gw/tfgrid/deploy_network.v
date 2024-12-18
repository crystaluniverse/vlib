module main

import freeflowuniverse.crystallib.data.rpcwebsocket { RpcWsClient }
import freeflowuniverse.crystallib.threefold.web3gw.tfgrid
import flag
import log
import os

const default_server_address = 'http://127.0.0.1:8080'

@[params]
pub struct Arguments {
	network          string = 'main'
	tfchain_mnemonic string
	ssh_key          string
}

fn execute_rpcs(mut client RpcWsClient, mut logger log.Logger, args Arguments) ! {
	mut tfgrid_client := tfgrid.new(mut client)

	tfgrid_client.load(network: args.network, mnemonic: args.tfchain_mnemonic)!

	deployment := tfgrid_client.deploy_network(
		name:    'mynetwork'
		network: tfgrid.NetworkConfiguration{
			name:                 'mynetwork'
			add_wireguard_access: true
		}
		vms:     [
			tfgrid.VMConfiguration{
				name:        'vm1'
				farm_id:     1
				cpu:         2
				memory:      2048
				rootfs_size: 1024
				public_ip6:  true
				env_vars:    {
					'SSH_KEY': args.ssh_key
				}
				disks:       [tfgrid.Disk{
					size:       10
					mountpoint: '/mnt/disk1'
				}]
			},
			tfgrid.VMConfiguration{
				name:        'vm2'
				farm_id:     1
				cpu:         2
				memory:      2048
				rootfs_size: 1024
				public_ip6:  true
				env_vars:    {
					'SSH_KEY': args.ssh_key
				}
				disks:       [tfgrid.Disk{
					size:       10
					mountpoint: '/mnt/disk1'
				}]
			},
		]
	)!
	logger.info('Network deployment: ${deployment}')
}

fn main() {
	mut fp := flag.new_flag_parser(os.args)
	fp.application('This tool allows you to deploy a vm on mainnet using ethereum. It requires you to have a valid ethereum mainnet account, some funds on it and a tfchain account')
	fp.limit_free_args(0, 0)!
	fp.description('')
	fp.skip_executable()

	address := fp.string('address', `a`, '${default_server_address}', 'The address of the web3_proxy server to connect to.')
	debug_log := fp.bool('debug', 0, false, 'By setting this flag the client will print debug logs too.')

	tfchain_mnemonic := fp.string('tfchain-mnemonic', 0, '', 'The mnemonic of your tfchain account.')
	network := fp.string('network', 0, 'main', 'The tfchain network to connect to.')
	ssh_key := fp.string('ssh-key', 0, '', 'The SSH key that can be used to ssh into the vm later.')

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

	arguments := Arguments{
		tfchain_mnemonic: tfchain_mnemonic
		ssh_key:          ssh_key
		network:          network
	}

	execute_rpcs(mut myclient, mut logger, arguments) or {
		logger.error('Failed executing calls: ${err}')
		exit(1)
	}
}
