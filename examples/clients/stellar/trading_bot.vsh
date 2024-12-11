#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.blockchain.stellar.tradingbot

mut bot := tradingbot.new(
	account_secret: 'SDKKNNX5NSYR62BUMIAZM6JDIGCUHYLWOHLM7NWICPVCOEIBF544TGM2'
	selling_asset_code: 'TFT'
	selling_asset_issuer: 'GCGE3IQWC4QIOJ7WVLIHZMXSE623CMXWQVMK4JWSRX2V3TXZEW3RHDR6'
	buying_asset_type: 'native'
	buying_target_price: 1
	selling_target_price: 100
	selling_amount: 500
	buying_amount: 10
	network: .testnet
)!

bot.run()!
