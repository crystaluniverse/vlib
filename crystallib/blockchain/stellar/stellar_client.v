module stellar

import os

const mainnet_passphrase = 'Public Global Stellar Network ; September 2015'
const mainnet_rpc_url = 'https://soroban-rpc.mainnet.stellar.gateway.fm'

const testnet_passphrase = 'Test SDF Network ; September 2015'
const testnet_rpc_url = 'https://soroban-rpc.testnet.stellar.gateway.fm'

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
	} else {
		remove_cached_keys(name: cl.account_name, network: cl.network)!
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
	cl.account_secret = keys.secret
	cl.account_address = keys.address

	return cl
}

fn (mut client StellarClient) add_keys() ! {
	cmd := 'SOROBAN_SECRET_KEY=${client.account_secret} stellar keys add ${client.account_name} --secret-key --quiet'
	result := os.execute(cmd)
	if result.exit_code != 0 {
		return error('Failed to add keys: ${result.output}')
	}
}

pub fn (mut client StellarClient) default_assetid_get() !string {
	result := os.execute('stellar contract id asset --asset native --network ${client.network} --quiet')
	if result.exit_code != 0 {
		return error('Failed to get asset contract ID: ${result.output}')
	}
	return result.output.trim_space()
}

pub struct NetworkConfig {
	url        string
	passphrase string
}

enum ThresholdLevel {
	low
	med
	high
}

pub struct Operation {
	source_address string
	threshold      ThresholdLevel
}

fn (mut client StellarClient) sign_with_signers(xdr_ string, ops []Operation, signers []string) !string {
	mut xdr := xdr_
	mut signers_ := signers.clone()
	mut signer_address_secret := map[string]string{} // Address:Secret
	mut signers_signed := map[string]bool{} // Address:Secret
	signers_ << client.account_secret

	for signer in signers_ {
		signer_address_secret[get_address(signer)!] = signer
	}

	for op in ops {
		source_acc := new_horizon_client(client.network)!.get_account(op.source_address)!
		mut current_weight := 0

		threshold := match op.threshold {
			.low {
				source_acc.thresholds.low_threshold
			}
			.med {
				source_acc.thresholds.med_threshold
			}
			.high {
				source_acc.thresholds.high_threshold
			}
		}

		for signer in source_acc.signers {
			if signers_signed[signer.key] {
				current_weight += signer.weight
			}
		}

		for signer in source_acc.signers {
			if current_weight >= threshold && current_weight > 0 {
				break
			}

			secret := signer_address_secret[signer.key] or { continue }
			if signers_signed[signer.key] {
				continue
			}

			signers_signed[signer.key] = true
			xdr = client.sign_tx(xdr, secret)!
			current_weight += signer.weight
		}
	}

	return xdr
}

@[params]
pub struct SendPaymentParams {
pub mut:
	asset         OfferAssetType = OfferAssetType('native')
	to            string         @[required]
	amount        int            @[required]
	source_secret ?string  // the secret of the source account
	signers       []string // secret of signers
}

pub fn (mut client StellarClient) payment_send(args SendPaymentParams) !string {
	mut source_secret := client.account_secret
	if v := args.source_secret {
		source_secret = v
	}

	network_config := get_network_config(client.network)!
	cmd := 'stellar tx new payment --asset ${args.asset} --source-account ${source_secret} --destination ${args.to} --amount ${args.amount} --build-only --network ${client.network} --rpc-url ${network_config.url} --network-passphrase "${network_config.passphrase}" --quiet'
	result := os.execute(cmd)
	if result.exit_code != 0 {
		return error('Failed to send payment: ${result.output}')
	}

	mut signers_ := args.signers.clone()
	signers_ << source_secret
	mut xdr := result.output.trim_space()
	xdr = client.sign_with_signers(xdr, [
		Operation{
			source_address: get_address(source_secret)!
			threshold: .med
		},
	], signers_)!

	tx_info := client.send_tx(xdr)!
	return tx_info.hash
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
	cmd := 'stellar tx new account-merge --source-account ${account_keys.secret} --account ${args.address} --network ${client.network} --quiet'
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

fn (mut client StellarClient) send_tx(tx string) !TransactionRecord {
	network_config := get_network_config(client.network)!

	cmd := 'echo "${tx}" | stellar tx send --network ${client.network} --rpc-url ${network_config.url} --network-passphrase "${network_config.passphrase}" --filter-logs=ERROR'
	result := os.execute(cmd)
	if result.exit_code != 0 {
		return error('Failed to send transaction: ${result.output}')
	}

	mut horizon_client := new_horizon_client(client.network)!
	tx_info := horizon_client.get_last_transaction(client.account_address)!
	return tx_info.embedded.records[0]
}

@[params]
pub struct StellarCreateAccountArgs {
pub mut:
	address          string
	starting_balance u64
	source_address   ?string
	signers          []string
}

pub fn (mut client StellarClient) create_account(args StellarCreateAccountArgs) !string {
	mut source_address := client.account_address
	if v := args.source_address {
		source_address = v
	}

	mut tx := client.new_transaction_envelope(client.account_address)!
	tx.add_create_account_op(client.account_address,
		destination: args.address
		starting_balance: args.starting_balance
	)!

	mut xdr := tx.xdr()!
	xdr = client.sign_with_signers(xdr, [
		Operation{
			source_address: source_address
			threshold: .med
		},
	], args.signers)!

	tx_info := client.send_tx(xdr)!
	return tx_info.hash
}

@[params]
pub struct AddChangeTrustArgs {
pub mut:
	asset_code     string   @[required]
	issuer         string   @[required]
	limit          u64 = (u64(1) << 63) - 1
	source_address ?string
	signers        []string
}

pub fn (mut client StellarClient) add_trust_line(args AddChangeTrustArgs) !string {
	mut tx := client.new_transaction_envelope(client.account_address)!
	tx.add_change_trust_op(args)!

	mut source_address := client.account_address
	if v := args.source_address {
		source_address = v
	}

	mut xdr := tx.xdr()!
	xdr = client.sign_with_signers(xdr, [
		Operation{
			source_address: source_address
			threshold: .med
		},
	], args.signers)!

	tx_info := client.send_tx(xdr)!
	return tx_info.hash
}

@[required]
pub struct OfferArgs {
pub mut:
	sell           bool
	buy            bool
	source_address ?string
	selling        OfferAssetType
	buying         OfferAssetType
	amount         u64            @[required]
	price          f32            @[required] // Price of 1 unit of selling in terms of buying
	signers        []string
}

fn (mut client StellarClient) make_offer(offer_id u64, args OfferArgs) !TransactionRecord {
	if args.sell == args.buy {
		return error('You must either sell or buy at the same time')
	}

	mut source_address := client.account_address
	if v := args.source_address {
		source_address = v
	}

	mut tx := client.new_transaction_envelope(client.account_address)!
	tx.make_offer_op(offer_id: offer_id, offer: args, sell: args.sell, buy: args.buy)!
	mut xdr := tx.xdr()!
	xdr = client.sign_with_signers(xdr, [
		Operation{
			source_address: source_address
			threshold: .med
		},
	], args.signers)!
	return client.send_tx(xdr)!
}

pub fn (mut client StellarClient) create_offer(args OfferArgs) !u64 {
	tx_record := client.make_offer(0, args)!
	cur_offer_id := get_offer_id_from_result_xdr(tx_record.result_xdr)!
	return cur_offer_id
}

pub fn (mut client StellarClient) update_offer(offer_id u64, args OfferArgs) ! {
	if args.amount == 0 {
		return error('Amount must be greater than 0')
	}

	client.make_offer(offer_id, args)!
}

pub fn (mut client StellarClient) delete_offer(offer_id u64, args_ OfferArgs) ! {
	mut args := args_
	args.amount = 0
	client.make_offer(offer_id, args)!
}
