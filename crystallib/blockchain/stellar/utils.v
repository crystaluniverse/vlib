module stellar

import freeflowuniverse.crystallib.clients.httpconnection
import os
import math
import x.json2

pub struct StellarAccountKeys {
pub:
	name    string
	address string
	secret  string
}

pub fn get_address(secret string) !string {
	cmd := 'stellar keys address ${secret} --quiet'
	result := os.execute(cmd)
	if result.exit_code != 0 {
		return error('Failed to get address: ${result.output}')
	}

	return result.output.trim_space()
}

pub fn get_account_keys(name string) !StellarAccountKeys {
	// Get the public key
	address_result := os.execute('stellar keys address ${name} --quiet')
	if address_result.exit_code != 0 {
		return error('Failed to get public key: ${address_result.output}')
	}
	address := address_result.output.trim_space()

	// Get the secret key
	show_result := os.execute('stellar keys show ${name} --quiet')
	if show_result.exit_code != 0 {
		return error('Failed to get secret key: ${show_result.output}')
	}
	secret := show_result.output.trim_space()

	// Return the StellarAccountKeys struct
	return StellarAccountKeys{
		name:    name
		address: address
		secret:  secret
	}
}

pub fn get_network_config(network StellarNetwork) !NetworkConfig {
	rpc_url, passphrase := match network {
		.mainnet {
			mainnet_rpc_url, mainnet_passphrase
		}
		.testnet {
			testnet_rpc_url, testnet_passphrase
		}
	}
	return NetworkConfig{
		url:        rpc_url
		passphrase: passphrase
	}
}

pub fn encode_tx_to_xdr(json_encoding string) !string {
	cmd := "echo '${json_encoding}' | stellar xdr encode --type TransactionEnvelope"
	result := os.execute(cmd)
	if result.exit_code != 0 {
		return error('failed to encode tx: ${result.output}')
	}

	return result.output.trim_space()
}

// Struct to hold arguments for creating a Stellar account.
@[params]
pub struct GenerateAccountArgs {
pub mut:
	network StellarNetwork = .testnet // Specifies the Stellar network (testnet or mainnet). Defaults to testnet.
	name    string @[required] // Name of the account. This is required.
	fund    bool // Whether to fund the account on the test network after creation.
	cache   bool // Whether to cache the generated keys locally.
}

// Generates a new Stellar account and returns the associated keys.
// This function generates a new Stellar account using the 'stellar keys generate' command.
// If the 'fund' parameter is true, the account is funded on the network.
// If the 'cache' parameter is true, the generated keys are cached locally.
//
// Arguments:
// - `args` (CreateAccountArgs): Struct containing account creation parameters.
//
// Returns:
// - `StellarAccountKeys`: Struct with the public and secret keys for the account.
//
// Errors:
// - Returns an error if key generation fails or cached key removal fails.
pub fn generate_keys(args GenerateAccountArgs) !StellarAccountKeys {
	// Validate the network.
	if args.network != .testnet && args.fund {
		return error('The fund parameter can only be set to true for the testnet network.')
	}

	// Construct the CLI command for generating Stellar keys.
	mut cmd := 'stellar keys generate ${args.name} --network ${args.network}'
	if args.fund {
		cmd += ' --fund'
	} else {
		cmd += ' --no-fund'
	}

	// Execute the command and check for errors.
	result := os.execute(cmd)
	if result.exit_code != 0 {
		return error('Failed to generate keys: ${result.output}')
	}

	// Retrieve the generated account keys.
	keys := get_account_keys(args.name) or { return error('Failed to get keys: ${err}') }

	// Optionally remove cached keys.
	if !args.cache {
		remove_cached_keys(name: keys.name) or {
			return error('Failed to remove cached keys: ${err}')
		}
	}

	return keys
}

// Struct to hold arguments for removing cached Stellar keys.
@[params]
pub struct RemoveCachedKeysArgs {
pub mut:
	network StellarNetwork = .testnet // Specifies the Stellar network (testnet or mainnet). Defaults to testnet.
	name    string @[required] // Name of the account. This is required.
}

// Removes cached Stellar keys for a specific account.
//
// Arguments:
// - `args` (RemoveCachedKeysArgs): Struct containing parameters for key removal.
//
// Errors:
// - Returns an error if the removal command fails.
fn remove_cached_keys(args RemoveCachedKeysArgs) ! {
	cmd := 'stellar keys rm ${args.name}'
	result := os.execute(cmd)
	if result.exit_code != 0 {
		return error('Failed to remove cached keys: ${result.output}')
	}
}

// Funds a Stellar account on the test network using Friendbot.
//
// Arguments:
// - `address` (string): The public key of the account to be funded.
//
// Errors:
// - Returns an error if the funding request fails.
pub fn fund_account(address string) ! {
	mut client := httpconnection.new(
		name: 'stellar'
		url:  'https://friendbot.stellar.org/'
	)!

	client.get(
		prefix: '?addr=${address}'
	)!
}

// Struct to hold a transaction signer.
@[params]
pub struct NewSignerArgs {
pub mut:
	key    string @[required] // Signer address
	weight int = 1 // Weight
}

// adding a new signer
pub fn new_signer(args NewSignerArgs) TXSigner {
	return TXSigner{
		key:    args.key
		weight: args.weight
	}
}

pub fn get_offer_price(price f32) Price {
	nums := price.str().split('.')
	n := int(price * int(math.pow(10, nums[1].len)))
	d := int(math.pow(10, nums[1].len))
	return Price{
		n: n
		d: d
	}
}

pub fn fetch_highest_bid_price(orderBook OrderBook) !Price {
	// Parse highest bid price from the order book response
	if orderBook.bids.len == 0 {
		return Price{
			n: 0
			d: 1
		}
	}

	println('highest bid: ${orderBook.bids[0].price}')
	return orderBook.bids[0].price_r
}

pub fn fetch_highest_ask_price(orderBook OrderBook) !Price {
	// Parse highest bid price from the order book response
	if orderBook.asks.len == 0 {
		return error('There are no asks.')
	}

	println('highest ask: ${orderBook.asks[0].price}')
	return orderBook.asks[0].price_r
}

pub fn get_offer_id_from_result_xdr(result_xdr string) !u64 {
	cmd := 'echo ${result_xdr} | stellar xdr decode --type TransactionResult'
	tx_result := os.execute(cmd)
	if tx_result.exit_code != 0 {
		return error('Failed to decode transaction result: ${tx_result.output}')
	}
	data := json2.raw_decode(tx_result.output.trim_space())!.as_map()
	println('data map: ${data}')
	return find_key_recursive(data, 'offer_id')!.u64()
}

fn find_key_recursive(data map[string]json2.Any, key_to_find string) !json2.Any {
	for key, value in data {
		if key == key_to_find {
			return value
		}

		if value is map[string]json2.Any {
			result := find_key_recursive(value as map[string]json2.Any, key_to_find) or { continue }
			return result
		}

		if value is []json2.Any {
			for item in value {
				if item is map[string]json2.Any {
					result := find_key_recursive(item as map[string]json2.Any, key_to_find) or {
						continue
					}
					return result
				}
			}
		}
	}

	return error('Key ${key_to_find} not found')
}

fn url_encode(map_ map[string]json2.Any) string {
	mut formated := ''

	for k, v in map_ {
		if formated != '' {
			formated += '&' + k + '=' + v.str()
		} else {
			formated = k + '=' + v.str()
		}
	}
	return formated
}
