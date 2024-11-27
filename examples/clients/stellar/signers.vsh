#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.blockchain.stellar

mut client := stellar.new_client(
	account_name:   'default'
	account_secret: 'SA5AH6PDCKPP4P7XNWX6W4SKVDS6C2GECH4BQDKPDG5JQC3GFRGAB377'
	network:        .testnet
	cache:          false
)!

// If you have a saved keys you can use the get_client method without specifying the account_secret.
// mut client := stellar.get_client(account_name:"default", network: .testnet)!

signer1 := stellar.new_signer(
	key:    'GBSQW44E3AHYFF5G2M7T64R3F25SUW3B64OXCTAGWS2J2ZWV67WGAI5V'
	weight: 3
)

signer2 := stellar.new_signer(
	key:    'GAXPE7LWNHKD4QKWJYCS5H4GZJHCYTLG45JOU3KRDZR65XSZTQK7OYLG'
	weight: 4
)

signer3 := stellar.new_signer(
	key:    'GANUFHCJIDAI347KLXHC6OK3H3Z7YRJQLH6IRBOHLRZ56KJ27LLTXOD7'
	weight: 5
)

mut hash := client.add_signers(
	signers_to_add: [signer1, signer2, signer3]
	signers:        [
		'SDFN5S2WBCFBZR675KZJM4FKYQ5WGNTPRUP4H3NR5DMHL753UBLUDDGF',
	]
)!
println('add signer tx hash: ${hash}')

hash2 := client.remove_signer(
	address: 'GBSQW44E3AHYFF5G2M7T64R3F25SUW3B64OXCTAGWS2J2ZWV67WGAI5V'
	signers: [
		'SDFN5S2WBCFBZR675KZJM4FKYQ5WGNTPRUP4H3NR5DMHL753UBLUDDGF',
	]
)!
println('remove signer tx hash: ${hash2}')
