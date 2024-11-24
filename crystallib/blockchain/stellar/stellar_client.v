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

// TODO: work with enum for network

pub struct StellarClient {
pub mut:
	network         string
	default_assetid string // default asset contract ID, can be empty
	default_from    string // default account to work default_from, can be empty
	default_account string // default name of the account
}

@[params]
pub struct StellarClientConfig {
pub:
	network         string
	default_assetid string // contract id of the asset
	default_from    string
	default_account string // default name of the account
}

pub fn new_stellar_client(config StellarClientConfig) !StellarClient {
	mut cl := StellarClient{
		network: config.network
		default_assetid: config.default_assetid
		default_from: config.default_from
		default_account: config.default_account
	}
	if cl.default_assetid == '' {
		cl.default_assetid = cl.default_assetid_get()!
	}
	return cl
}

@[params]
pub struct AddKeysArgs {
pub:
	source_account_name ?string
	secret              string
}

pub fn (mut client StellarClient) add_keys(args AddKeysArgs) ! {
	mut account_name := client.default_account

	if v := args.source_account_name {
		account_name = v
	}

	cmd := 'SOROBAN_SECRET_KEY=${args.secret} stellar keys add ${account_name} --secret-key --quiet'
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

	return client.account_keys_get(name)
}

pub fn (mut client StellarClient) account_keys_get(name string) !StellarAccountKeys {
	// Get the public key
	address_result := os.execute('stellar keys address ${name} --quiet')
	if address_result.exit_code != 0 {
		return error('Failed to get public key: ${address_result.output}')
	}
	public_key := address_result.output.trim_space()

	// Get the secret key
	show_result := os.execute('stellar keys show ${name} --quiet')
	if show_result.exit_code != 0 {
		return error('Failed to get secret key: ${show_result.output}')
	}
	secret_key := show_result.output.trim_space()

	// Return the StellarAccountKeys struct
	return StellarAccountKeys{
		name: name
		public_key: public_key
		secret_key: secret_key
	}
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
	network        ?string
	asset          string = 'native'
	source_account ?string // secret of source account
	to             string  @[required]
	amount         int     @[required]

	signers []string
}

pub struct NetworkConfig {
	url string
	passphrase string
}

pub fn get_network_config(network_name string) !NetworkConfig {
	rpc_url, passphrase := match network_name {
		'mainnet' {
			stellar.mainnet_rpc_url, stellar.mainnet_passphrase
		}
		'testnet' {
			stellar.testnet_rpc_url, stellar.testnet_passphrase
		}
		else {
			return error('invalid network ${network_name}')
		}
	}
	return NetworkConfig{
		url: rpc_url
		passphrase: passphrase
	}
}

pub fn (mut client StellarClient) payment_send(args SendPaymentParams) ! {
	source_account := if v := args.source_account {
		v
	} else {
		account_keys := client.account_keys_get(client.default_account)!
		account_keys.secret_key
	}

	network_name := if v := args.network {
		v
	} else {
		client.network
	}

	network_config := get_network_config(network_name)!
	cmd := 'stellar tx new payment --asset ${args.asset} --source-account ${source_account} --destination ${args.to} --amount ${args.amount} --build-only --network ${network_name} --rpc-url ${network_config.url} --network-passphrase "${network_config.passphrase}" --quiet'
	result := os.execute(cmd)
	if result.exit_code != 0 {
		return error('Failed to send payment: ${result.output}')
	}
	mut tx := result.output.trim_space()

	source_address := client.get_address(source_account)!
	mut signer_address_secret := map[string]string{}
	signer_address_secret[client.get_address(source_account)!] = source_account
	for signer in args.signers {
		signer_address_secret[client.get_address(signer)!] = signer
	}

	source_acc := new_horizon_client(network_name)!.get_account(source_address)!
	mut current_threshold := 0
	threshold := source_acc.thresholds.med_threshold
	for signer in source_acc.signers {
		secret := signer_address_secret[signer.key] or { continue }

		tx = client.sign_tx(tx, secret, network_name)!
		current_threshold += signer.weight
		if current_threshold >= threshold {
			break
		}
	}

	client.send_tx(tx, network_name)!
}

@[params]
pub struct CheckBalanceParams {
	assetid    string
	account_id string
}

pub fn (mut client StellarClient) balance_check(params CheckBalanceParams) !string {
	asset_id := if params.assetid == '' { client.default_assetid } else { params.assetid }
	cmd := 'stellar contract invoke --id ${asset_id} --source-account ${params.account_id} --network ${client.network} -- balance --id ${params.account_id} --quiet'
	result := os.execute(cmd)
	if result.exit_code != 0 {
		return error('Failed to check balance: ${result.output}')
	}
	return result.output.trim_space()
}

@[params]
pub struct MergeArgs {
pub:
	source_account_name ?string
	address             string
}

pub fn (mut client StellarClient) merge_accounts(args MergeArgs) ! {
	mut account_name := client.default_account

	if v := args.source_account_name {
		account_name = v
	}

	account_keys := client.account_keys_get(account_name)!
	cmd := 'stellar tx new account-merge --source-account ${account_keys.secret_key} --account ${args.address} --network ${client.network} --quiet'
	result := os.execute(cmd)
	if result.exit_code != 0 {
		return error('Failed to add keys: ${result.output}')
	}
}

fn (mut client StellarClient) get_address(secret string) !string {
	cmd := 'stellar keys address ${secret} --quiet'
	result := os.execute(cmd)
	if result.exit_code != 0 {
		return error('Failed to get address: ${result.output}')
	}

	return result.output.trim_space()
}

fn (mut client StellarClient) sign_tx(tx string, signer string, network string) !string {
	network_config := get_network_config(network)!

	cmd := 'echo "${tx}" | stellar tx sign --sign-with-key ${signer} --network ${network} --rpc-url "${network_config.url}" --network-passphrase "${network_config.passphrase}" --quiet'
	result := os.execute(cmd)
	if result.exit_code != 0 {
		return error('Failed to sign transaction: ${result.output}')
	}

	return result.output.trim_space()
}

fn (mut client StellarClient) send_tx(tx string, network string) ! {
	network_config := get_network_config(network)!

	cmd := 'echo "${tx}" | stellar tx send --network ${network} --rpc-url ${network_config.url} --network-passphrase "${network_config.passphrase}" --filter-logs=ERROR'
	result := os.execute(cmd)
	if result.exit_code != 0 {
		return error('Failed to send transaction: ${result.output}')
	}
}
