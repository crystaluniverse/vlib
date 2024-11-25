#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.blockchain.stellar


mut client := stellar.new_client(
	account_name:"default",
	account_secret: "SA5AH6PDCKPP4P7XNWX6W4SKVDS6C2GECH4BQDKPDG5JQC3GFRGAB377",
	network: .testnet
)!

// mut client := stellar.get_client(account_name:"default", network: .testnet)!

mut hash := client.add_signers(signers: [stellar.TXSigner{
	key: 'GBSQW44E3AHYFF5G2M7T64R3F25SUW3B64OXCTAGWS2J2ZWV67WGAI5V'
	weight: 3
}, stellar.TXSigner{
	key: 'GAXPE7LWNHKD4QKWJYCS5H4GZJHCYTLG45JOU3KRDZR65XSZTQK7OYLG'
	weight: 4
}, stellar.TXSigner{
	key: 'GANUFHCJIDAI347KLXHC6OK3H3Z7YRJQLH6IRBOHLRZ56KJ27LLTXOD7'
	weight: 5
}])!
println('add signer tx hash: ${hash}')

hash = client.remove_signer(address: 'GBSQW44E3AHYFF5G2M7T64R3F25SUW3B64OXCTAGWS2J2ZWV67WGAI5V')!
println('remove signer tx hash: ${hash}')
