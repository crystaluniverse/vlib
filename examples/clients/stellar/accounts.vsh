#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.blockchain.stellar

// mut client := stellar.new_client(
// 	account_name:"default",
// 	account_secret: "SA5AH6PDCKPP4P7XNWX6W4SKVDS6C2GECH4BQDKPDG5JQC3GFRGAB377",
// 	network: .testnet
// )!

println('Creating a new account 1')
account1 := stellar.generate_keys(name: 'account1', network: .testnet)!
println('Account 1: ${account1}')

println('Creating a new account 2')
// Use generate account on testnet with fund=true to add the trustline
account2 := stellar.generate_keys(name: 'account2', network: .testnet, fund: true)!
println('Account 2: ${account2}')

mut client := stellar.new_client(
	account_name:   account2.name
	account_secret: account2.secret
	network:        .testnet
	cache:          false
)!

// Use this method to add the trustline to the account
tx := client.create_account(address: account1.address, starting_balance: 10000000)!

println('tx: ${tx}')
