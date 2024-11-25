#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.blockchain.stellar


mut client := stellar.new_client(
	account_name:"default",
	account_secret: "SBUG7WNI6EACVNFQBWE74JDBB2PI5FSEMPMHQJSFZTLWO2XORDSIW6PV",
	network: .testnet
)!

// mut client := stellar.get_client(account_name:"default", network: .testnet)!
mut hash := client.add_trust_line(asset_code: 'TFT', issuer: 'GA47YZA3PKFUZMPLQ3B5F2E3CJIB57TGGU7SPCQT2WAEYKN766PWIMB3')!
println('hash: ${hash}')
