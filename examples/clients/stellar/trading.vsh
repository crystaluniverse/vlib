#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.blockchain.stellar

tft_issuer := 'GCGE3IQWC4QIOJ7WVLIHZMXSE623CMXWQVMK4JWSRX2V3TXZEW3RHDR6'

account1 := stellar.generate_keys(name: 'account1', network: .testnet, fund: true)!
println('Account 1: ${account1}')

mut client := stellar.new_client(
	account_name: 'default'
	account_secret: account1.secret
	network: .testnet
	cache: false
)!

mut hash := client.add_trust_line(
	asset_code: 'TFT'
	issuer: tft_issuer // tft issuer id
)!
println('add tft trustline tx hash: ${hash}')

// Make sell offer
sell_offer_args := stellar.OfferArgs{
	selling: stellar.OfferAssetType('native')
	buying: stellar.OfferAssetType(stellar.new_asset_type('TFT', tft_issuer))
	sell: true
	amount: 50
	price: 10
}
mut sell_offer_result := client.create_offer(sell_offer_args)!
if sell_offer_result.claimed {
	println('Offer created and claimed by ${sell_offer_result.offer_id}')
} else {
	println('Offer ${sell_offer_result.offer_id} is created')
}

// Make buy offer
mut buy_offer_args := stellar.OfferArgs{
	selling: stellar.OfferAssetType('native')
	buying: stellar.OfferAssetType(stellar.new_asset_type('TFT', tft_issuer))
	buy: true
	amount: 50
	price: 10
}

mut buy_offer_result := client.create_offer(buy_offer_args)!
if buy_offer_result.claimed {
	println('Offer created and claimed by ${buy_offer_result.offer_id}')
} else {
	println('Offer ${buy_offer_result.offer_id} is created')
}

buy_offer_args.amount = 100
client.update_offer(buy_offer_id, buy_offer_args)!
println('offer ${buy_offer_id} is update')

client.delete_offer(sell_offer_id, sell_offer_args)!
println('sell offer ${sell_offer_id} is deleted')
