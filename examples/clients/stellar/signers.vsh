#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.blockchain.stellar

account1 := stellar.generate_keys(name: 'account1', network: .testnet, fund: true)!
println('Account 1: ${account1}')

account2 := stellar.generate_keys(name: 'account2', network: .testnet, fund: true)!
println('Account 2: ${account2}')

account3 := stellar.generate_keys(name: 'account3', network: .testnet, fund: true)!
println('Account 3: ${account3}')

mut client := stellar.new_client(
	account_name:   'default'
	account_secret: account1.secret
	network:        .testnet
	cache:          false
)!

// If you have a saved keys you can use the get_client method without specifying the account_secret.
// mut client := stellar.get_client(account_name:"default", network: .testnet)!

signer1 := stellar.new_signer(
	key:    account1.address
	weight: 3
)

signer2 := stellar.new_signer(
	key:    account2.address
	weight: 4
)

signer3 := stellar.new_signer(
	key:    account3.address
	weight: 5
)

mut hash := client.add_signers(
	signers_to_add: [signer1, signer2, signer3] // signers to add to this account
	signers:        [account1.secret]           // signers that may sign this transaction
)!
println('add signer tx hash: ${hash}')

hash2 := client.remove_signer(
	address: account2.address  // signer to remove
	signers: [account3.secret] // signers that may sign this transaction
)!
println('remove signer tx hash: ${hash2}')
