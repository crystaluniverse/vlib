#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.blockchain.stellar.tradingbot
import freeflowuniverse.crystallib.blockchain.stellar

// account1 := stellar.generate_keys(name: 'account1', network: .testnet, fund: true)!
// println('Account 1: ${account1}')

tft_issuer := 'GCGE3IQWC4QIOJ7WVLIHZMXSE623CMXWQVMK4JWSRX2V3TXZEW3RHDR6'

mut bot := tradingbot.new(
	account_secret: 'SDKKNNX5NSYR62BUMIAZM6JDIGCUHYLWOHLM7NWICPVCOEIBF544TGM2'
	buying_asset_type: 'native'
	selling_asset_code: 'TFT'
	selling_asset_issuer: tft_issuer
	selling_target_price: 1000
	buying_target_price: 0.0001
	selling_amount: 10
	buying_amount: 10
	network: .testnet
)!

bot.run()!
