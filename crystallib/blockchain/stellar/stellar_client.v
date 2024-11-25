module stellar

import os

const mainnet_passphrase = 'Public Global Stellar Network ; September 2015'
const mainnet_rpc_url = 'https://soroban-rpc.mainnet.stellar.gateway.fm'

const testnet_passphrase = 'Test SDF Network ; September 2015'
const testnet_rpc_url = 'https://soroban-rpc.testnet.stellar.gateway.fm'

pub struct StellarAccountKeys {
pub:
	name       string
	public_key string
	secret_key string
}

pub enum StellarNetwork {
	mainnet
	testnet
}

pub struct StellarClient {
pub mut:
	network         StellarNetwork
	account_name    string
	account_secret  string
	account_address string
}

@[params]
pub struct NewStellarClientArgs {
pub:
	network        StellarNetwork = .testnet
	account_name   string
	account_secret string         @[required]
	cache          bool = true // If you do not want to cache account keys, set to false. If it is true and you send the same account name twice, the saved keys will be overwritten.
}

pub fn new_client(config NewStellarClientArgs) !StellarClient {
	account_address := get_address(config.account_secret)!
	mut cl := StellarClient{
		network: config.network
		account_name: config.account_name
		account_secret: config.account_secret
		account_address: account_address
	}

	// Cache the account keys
	if config.cache {
		cl.add_keys()!
	}

	return cl
}

@[params]
pub struct GetStellarClientArgs {
pub:
	network      StellarNetwork = .testnet
	account_name string
}

pub fn get_client(config GetStellarClientArgs) !StellarClient {
	mut cl := StellarClient{
		network: config.network
		account_name: config.account_name
	}

	mut keys := get_account_keys(cl.account_name)!
	cl.account_secret = keys.secret_key
	cl.account_address = keys.public_key

	return cl
}

pub fn (mut client StellarClient) add_keys() ! {
	cmd := 'SOROBAN_SECRET_KEY=${client.account_secret} stellar keys add ${client.account_name} --secret-key --quiet'
	result := os.execute(cmd)
	if result.exit_code != 0 {
		return error('Failed to add keys: ${result.output}')
	}
}

pub fn (mut client StellarClient) account_new(name string) !StellarAccountKeys {
	// Generate the keys
	result := os.execute('stellar keys generate ${name} --network ${client.network} --quiet')
	if result.exit_code != 0 {
		return error('Failed to generate keys: ${result.output}')
	}

	return get_account_keys(name)
}

pub fn (mut client StellarClient) account_fund(name string) !u64 {
	result := os.execute('stellar keys fund ${name} --network ${client.network} --quiet')
	if result.exit_code != 0 {
		return error('Failed to fund account, maybe you are not on testnet: ${result.output}')
	}

	// TODO: check funding is there and return

	return 0
}

pub fn (mut client StellarClient) default_assetid_get() !string {
	result := os.execute('stellar contract id asset --asset native --network ${client.network} --quiet')
	if result.exit_code != 0 {
		return error('Failed to get asset contract ID: ${result.output}')
	}
	return result.output.trim_space()
}

@[params]
pub struct SendPaymentParams {
pub mut:
	asset                 string = 'native'
	source_account_secret ?string // secret of source account
	to                    string   @[required]
	amount                int      @[required]
	signers               []string // secret of signers
}

pub struct NetworkConfig {
	url        string
	passphrase string
}

pub fn (mut client StellarClient) payment_send(args SendPaymentParams) !string {
	source_account := if v := args.source_account_secret {
		v
	} else {
		account_keys := get_account_keys(client.account_name)!
		account_keys.secret_key
	}

	network_config := get_network_config(client.network)!
	cmd := 'stellar tx new payment --asset ${args.asset} --source-account ${source_account} --destination ${args.to} --amount ${args.amount} --build-only --network ${client.network} --rpc-url ${network_config.url} --network-passphrase "${network_config.passphrase}" --quiet'
	result := os.execute(cmd)
	if result.exit_code != 0 {
		return error('Failed to send payment: ${result.output}')
	}
	mut tx := result.output.trim_space()

	source_address := get_address(source_account)!
	mut signer_address_secret := map[string]string{}
	signer_address_secret[get_address(source_account)!] = source_account
	for signer in args.signers {
		signer_address_secret[get_address(signer)!] = signer
	}

	source_acc := new_horizon_client(client.network)!.get_account(source_address)!
	mut current_threshold := 0
	threshold := source_acc.thresholds.med_threshold
	for signer in source_acc.signers {
		secret := signer_address_secret[signer.key] or { continue }

		tx = client.sign_tx(tx, secret)!
		current_threshold += signer.weight
		if current_threshold >= threshold {
			break
		}
	}

	return client.send_tx(tx)!
}

// TODO: Check what is wrong with this method.
// @[params]
// pub struct CheckBalanceParams {
// 	assetid    string = "native"
// 	account_id string
// }

// pub fn (mut client StellarClient) balance_check(params CheckBalanceParams) !string {
// 	asset_id := if params.assetid == '' { client.default_assetid } else { params.assetid }
// 	cmd := 'stellar contract invoke --id ${asset_id} --source-account ${params.account_id} --network ${client.network} -- balance --id ${params.account_id} --quiet'
// 	result := os.execute(cmd)
// 	if result.exit_code != 0 {
// 		return error('Failed to check balance: ${result.output}')
// 	}
// 	return result.output.trim_space()
// }

@[params]
pub struct MergeArgs {
pub:
	source_account_name ?string
	address             string
}

pub fn (mut client StellarClient) merge_accounts(args MergeArgs) ! {
	mut account_name := client.account_name

	if v := args.source_account_name {
		account_name = v
	}

	account_keys := get_account_keys(account_name)!
	cmd := 'stellar tx new account-merge --source-account ${account_keys.secret_key} --account ${args.address} --network ${client.network} --quiet'
	result := os.execute(cmd)
	if result.exit_code != 0 {
		return error('Failed to add keys: ${result.output}')
	}
}

fn (mut client StellarClient) sign_tx(tx string, signer string) !string {
	network_config := get_network_config(client.network)!

	cmd := 'echo "${tx}" | stellar tx sign --sign-with-key ${signer} --network ${client.network} --rpc-url "${network_config.url}" --network-passphrase "${network_config.passphrase}" --quiet'
	result := os.execute(cmd)
	if result.exit_code != 0 {
		return error('Failed to sign transaction: ${result.output}')
	}

	return result.output.trim_space()
}

fn (mut client StellarClient) send_tx(tx string) !string {
	network_config := get_network_config(client.network)!

	cmd := 'echo "${tx}" | stellar tx send --network ${client.network} --rpc-url ${network_config.url} --network-passphrase "${network_config.passphrase}" --filter-logs=ERROR'
	result := os.execute(cmd)
	if result.exit_code != 0 {
		return error('Failed to send transaction: ${result.output}')
	}

	mut horizon_client := new_horizon_client(client.network)!
	tx_info := horizon_client.get_last_transaction(client.account_address)!
	return tx_info.embedded.records[0].hash
}
