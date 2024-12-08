#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.blockchain.stellar.tradingbot

// 1. Initialize the stellar bot using the wallet secret
mut bot := tradingbot.new(
	account_secret:       'SBUG7WNI6EACVNFQBWE74JDBB2PI5FSEMPMHQJSFZTLWO2XORDSIW6PV'
	selling_asset_code:   'TFT'
	selling_asset_issuer: 'GA47YZA3PKFUZMPLQ3B5F2E3CJIB57TGGU7SPCQT2WAEYKN766PWIMB3'
	buying_asset_type:    'native'
	buying_target_price:  0.10
	selling_target_price: 50
	selling_amount:       1
	buying_amount:        1
	network:              .testnet
	// selling_asset_issuer: 'GBLPAOIUJCBIJWQTGVP4HKKQ7G45DLQZVPLENECSFL6IDC7FSXZC3DP7'
)!

bot.run()!
// bot.run(.buy)!
