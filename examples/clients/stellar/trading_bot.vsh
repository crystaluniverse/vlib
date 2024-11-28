#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.blockchain.stellar.tradingbot

// 1. Initialize the stellar bot using the wallet secret
mut bot := tradingbot.new(
	account_secret:       'SBUG7WNI6EACVNFQBWE74JDBB2PI5FSEMPMHQJSFZTLWO2XORDSIW6PV'
	buying_target_price:  '0.00001'
	buying_asset_code:    'USDC'
	buying_asset_issuer:  'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5'
	selling_target_price: '0.00002'
	selling_asset_code:   'XLM'
	network:              .testnet
)!

bot.run_buy_and_sell()!
// bot.run_buy()!
// bot.run_sell()!

// bot.run_and_wait()!
// // 2. Support a real-time checking to get the current price of a spacific token eg. XLM
// bot.start(.testnet)!
