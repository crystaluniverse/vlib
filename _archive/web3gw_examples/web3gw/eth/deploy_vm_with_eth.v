module main

import freeflowuniverse.crystallib.data.rpcwebsocket { RpcWsClient }
import freeflowuniverse.crystallib.threefold.web3gw.eth
import freeflowuniverse.crystallib.threefold.web3gw.stellar
import freeflowuniverse.crystallib.threefold.web3gw.tfchain
import freeflowuniverse.crystallib.threefold.web3gw.tfgrid
import flag
import log
import os

const default_server_address = 'http://127.0.0.1:8080'
const mainnet_ethereum_node = 'ws://185.69.167.224:8546'

@[params]
pub struct Arguments {
	eth_secret       string
	tfchain_mnemonic string
	ssh_key          string
}

fn execute_rpcs(mut client RpcWsClient, mut logger log.Logger, args Arguments) ! {
	mut eth_client := eth.new(mut client)
	mut tfchain_client := tfchain.new(mut client)
	mut stellar_client := stellar.new(mut client)
	mut tfgrid_client := tfgrid.new(mut client)

	eth_client.load(url: mainnet_ethereum_node, secret: args.eth_secret)!
	tfchain_client.load(network: 'main', mnemonic: args.tfchain_mnemonic)!
	tfgrid_client.load(network: 'main', mnemonic: args.tfchain_mnemonic)!

	stellar_account_secret := eth_client.create_stellar_account('public')!
	stellar_client.load(network: 'public', secret: stellar_account_secret)!
	stellar_address := stellar_client.address()!
	logger.info('Created stellar account ${stellar_address}')

	address := eth_client.address()!

	mut eth_balance := eth_client.balance(account: address)!
	logger.info('eth balance: ${eth_balance}')

	mut eth_tft_balance := eth_client.balance(account: address, asset: 'tft')!
	logger.info('eth tft balance: ${eth_tft_balance}')

	eth_to_swap := '0.0001'

	quote := eth_client.quote(amount: eth_to_swap)!
	logger.info('should receive ${quote} tft after swap')

	tx := eth_client.swap(amount: eth_to_swap)!
	logger.info('swapped eth for tft: tx: ${tx}')

	eth_balance = eth_client.balance(account: address)!
	logger.info('eth balance: ${eth_balance}')

	eth_tft_balance = eth_client.balance(account: address, asset: 'tft')!
	logger.info('eth tft balance: ${eth_tft_balance}')

	hash_bridge_to_stellar := eth_client.bridge_to_stellar(
		destination: stellar_address
		amount:      quote
	)!
	stellar_client.await_bridged_from_ethereum(memo: hash_bridge_to_stellar)!
	logger.info('bridge to stellar done')

	eth_tft_balance = eth_client.balance(account: address, asset: 'tft')!
	logger.info('eth tft balance: ${eth_tft_balance}')

	mut stellar_balance := stellar_client.balance(address: stellar_address)!
	logger.info('stellar balance: ${stellar_balance}')

	tfchain_address := tfchain_client.address()!
	tfchain_twinid := tfchain_client.get_twin_by_pubkey(tfchain_address)!

	mut tfchain_balance := tfchain_client.balance(tfchain_address)!
	logger.info('tft balance: ${tfchain_balance}')

	hash_bridge_to_tfchain := stellar_client.bridge_to_tfchain(
		amount:  stellar_balance
		twin_id: tfchain_twinid
	)!
	tfchain_client.await_bridged_from_stellar(hash_bridge_to_tfchain)!
	logger.info('bridge to tfchain done')

	stellar_balance = stellar_client.balance(address: stellar_address)!
	logger.info('stellar balance: ${stellar_balance}')

	tfchain_balance = tfchain_client.balance(tfchain_address)!
	logger.info('tft balance: ${tfchain_balance}')

	machines_deployment := tfgrid_client.deploy_vm(tfgrid.DeployVM{
		add_wireguard_access: false
		name:                 'vm1'
		farm_id:              1
		cpu:                  2
		memory:               2048
		rootfs_size:          1024
		public_ip6:           true
		env_vars:             {
			'SSH_KEY': args.ssh_key
		}
		disks:                [
			tfgrid.Disk{
				size:       10
				mountpoint: '/mnt/disk1'
			},
		]
		description:          'My deployment using ethereum'
	})!
	logger.info('machines deployment: ${machines_deployment}')
}

fn main() {
	mut fp := flag.new_flag_parser(os.args)
	fp.application('This tool allows you to deploy a vm on mainnet using ethereum. It requires you to have a valid ethereum mainnet account, some funds on it and a tfchain account')
	fp.limit_free_args(0, 0)!
	fp.description('')
	fp.skip_executable()

	address := fp.string('address', `a`, '${default_server_address}', 'The address of the web3_proxy server to connect to.')
	debug_log := fp.bool('debug', 0, false, 'By setting this flag the client will print debug logs too.')

	eth_secret := fp.string('eth-secret', 0, '', 'The secret to use for eth.')

	tfchain_mnemonic := fp.string('tfchain-mnemonic', 0, '', 'The mnemonic of your tfchain account.')

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
		eth_secret:       eth_secret
		tfchain_mnemonic: tfchain_mnemonic
		ssh_key:          ssh_key
	}

	execute_rpcs(mut myclient, mut logger, arguments) or {
		logger.error('Failed executing calls: ${err}')
		exit(1)
	}
}
