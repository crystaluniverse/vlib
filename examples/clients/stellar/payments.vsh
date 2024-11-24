#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.blockchain.stellar

mut client := stellar.new_stellar_client(
	network: 'testnet',
	default_account: 'SA5AH6PDCKPP4P7XNWX6W4SKVDS6C2GECH4BQDKPDG5JQC3GFRGAB377'
)!

// client.add_signer(
// 	signer: stellar.SignerAddress{
// 		address: 'GBSQW44E3AHYFF5G2M7T64R3F25SUW3B64OXCTAGWS2J2ZWV67WGAI5V'
// 		weight: 3
// 	}
// )!

// client.add_signer(
// 	signer: stellar.SignerAddress{
// 		address: 'GAXPE7LWNHKD4QKWJYCS5H4GZJHCYTLG45JOU3KRDZR65XSZTQK7OYLG'
// 		weight: 3
// 	}
// )!

client.payment_send(
	to: "GBSQW44E3AHYFF5G2M7T64R3F25SUW3B64OXCTAGWS2J2ZWV67WGAI5V",
	amount: int(200),
	signers: [
		// "SBUG7WNI6EACVNFQBWE74JDBB2PI5FSEMPMHQJSFZTLWO2XORDSIW6PV",
		// "SDFN5S2WBCFBZR675KZJM4FKYQ5WGNTPRUP4H3NR5DMHL753UBLUDDGF",
		// // To be removed.
		// // GANUFHCJIDAI347KLXHC6OK3H3Z7YRJQLH6IRBOHLRZ56KJ27LLTXOD7
		"SA5AH6PDCKPP4P7XNWX6W4SKVDS6C2GECH4BQDKPDG5JQC3GFRGAB377",
	]
)!

println('Client: ${client}')
