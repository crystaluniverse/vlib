#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.blockchain.stellar

// create and fund a new account on testnet
generated_account := stellar.generate_keys(name: 'account', network: .testnet, fund: true)!
println('Account: ${generated_account}')

mut stellar_client := stellar.new_client(
	account_name: generated_account.name
	account_secret: generated_account.secret
	network: .testnet
	cache: false
)!

mut horizon_client := stellar.new_horizon_client(.testnet)!

// get account information
mut account := horizon_client.get_account(generated_account.address)!
println('account: ${account}')

// get infromation about last transaction for this account
last_tx := horizon_client.get_last_transaction(generated_account.address)!
println('last tx: ${last_tx}')
