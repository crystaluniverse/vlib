module main

import freeflowuniverse.crystallib.data.rpcwebsocket { RpcWsClient }
import freeflowuniverse.crystallib.threefold.web3gw.tfchain
import flag
import log
import os

const default_server_address = 'ws://127.0.0.1:8080'

fn execute_rpcs(mut client RpcWsClient, mut logger log.Logger, mnemonic string) ! {
	mut tfchain_client := tfchain.new(mut client)

	tfchain_client.load(network: 'testnet', mnemonic: mnemonic)!

	// tfchain_client.transfer(tfchain.Transfer{amount: 1000, destination: "5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY"})! // FILL IN SOME DESTINATION

	my_balance := tfchain_client.balance('5Ek9gJ3iQFyr1HB5aTpqThqbGk6urv8Rnh9mLj5PD6GA26MS')! // FILL IN ADDRESS
	logger.info('My balance: ${my_balance}')

	// alice_balance := tfchain_client.balance("5GNJqTPyNqANBkUVMN1LPPrxXnFouWXoe2wNSmmEoLctxiZY")!
	// logger.info("Alice's balance: ${alice_balance}")

	height := tfchain_client.height()!
	logger.info('Height is ${height}')

	twin_164 := tfchain_client.get_twin(164)! // decoding to json is not yet working but add --debug and you will see the received message from server
	logger.info('Twin with id 164: ${twin_164}')

	twin_id := tfchain_client.get_twin_by_pubkey('5Ek9gJ3iQFyr1HB5aTpqThqbGk6urv8Rnh9mLj5PD6GA26MS')!
	logger.info('Twin id is ${twin_id}')

	node := tfchain_client.get_node(15)!
	logger.info('Node with id 15: ${node}')

	node_contracts_for_node_15 := tfchain_client.get_node_contracts(15)!
	logger.info('Node contracts for node 15: ${node_contracts_for_node_15}')

	for contract_id in node_contracts_for_node_15[..3] {
		logger.info('Getting contract ${contract_id}')
		contract := tfchain_client.get_contract(contract_id)!
		logger.info('Contract ${contract_id}: ${contract}')
	}
	if node_contracts_for_node_15.len > 0 {
		tfchain_client.cancel_contract(node_contracts_for_node_15[0]) or {
			logger.info("Can't cancel contract ${node_contracts_for_node_15[0]}. That's normal, it's not mine: ${err}")
		}
	}

	nodes := tfchain_client.get_nodes(1)!
	logger.info('Nodes of farm 1: ${nodes}')

	farm := tfchain_client.get_farm(1)!
	logger.info('Farm with id 1: ${farm}')

	farm_2 := tfchain_client.get_farm_by_name(farm.name)!
	logger.info('Farm with name Freefarm: ${farm_2}')

	zos_version := tfchain_client.get_zos_version()!
	logger.info('Zos version is: ${zos_version}')
}

fn main() {
	mut fp := flag.new_flag_parser(os.args)
	fp.application('Welcome to the web3_proxy client. The web3_proxy client allows you to execute all remote procedure calls that the web3_proxy server can handle.')
	fp.limit_free_args(0, 0)!
	fp.description('')
	fp.skip_executable()
	mnemonic := fp.string('mnemonic', `m`, '', 'The mnemonic to be used to call any function')
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

	execute_rpcs(mut myclient, mut logger, mnemonic) or {
		logger.error('Failed executing calls: ${err}')
		exit(1)
	}
}
