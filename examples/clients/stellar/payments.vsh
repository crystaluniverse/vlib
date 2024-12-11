#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.blockchain.stellar

account1 := stellar.generate_keys(name: 'account1', network: .testnet, fund: true)!
println('Account 1: ${account1}')

account2 := stellar.generate_keys(name: 'account2', network: .testnet, fund: true)!
println('Account 2: ${account2}')

account3 := stellar.generate_keys(name: 'account3', network: .testnet, fund: true)!
println('Account 3: ${account3}')

mut client := stellar.new_client(
	account_name: 'default'
	account_secret: account1.secret
	network: .testnet
	cache: false
)!

mut signers := [
	account2.secret,
	account3.secret,
]

// every operation belongs to one of the thresholds (low, med, high)
// a payment oepration uses the med threshold
mut hash := client.update_threshold(med_threshold: 5)!
println('update threshold tx hash: ${hash}')

signer1 := stellar.new_signer(
	key: account1.address
	weight: 3
)

signer2 := stellar.new_signer(
	key: account2.address
	weight: 4
)

signer3 := stellar.new_signer(
	key: account3.address
	weight: 5
)

mut hash2 := client.add_signers(
	signers_to_add: [signer1, signer2, signer3]
)!
println('add signer tx hash: ${hash2}')

// this would fail if we don't add enough singers
hash2 = client.payment_send(
	to: account2.address
	amount: int(200)
	signers: signers
)!
println('payment tx hash: ${hash2}')
