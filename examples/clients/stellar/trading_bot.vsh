#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.blockchain.stellar.tradingbot

// 1. Initialize the stellar bot using the wallet secret
mut bot := tradingbot.new(
	account_secret:       'SBUG7WNI6EACVNFQBWE74JDBB2PI5FSEMPMHQJSFZTLWO2XORDSIW6PV'
	buying_target_price:  '2'
	buying_asset_code:    'USDC'
	buying_asset_issuer:  'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5'
	selling_target_price: '2'
	selling_asset_code:   'XLM'
	network:              .testnet
	sell_amount:          '0'
	// selling_asset_issuer: 'GBLPAOIUJCBIJWQTGVP4HKKQ7G45DLQZVPLENECSFL6IDC7FSXZC3DP7'
)!

bot.run_buy_and_sell()!
