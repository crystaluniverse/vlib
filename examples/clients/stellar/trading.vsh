#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.blockchain.stellar

mut client := stellar.new_client(
	account_name:   'default'
	account_secret: 'SBUG7WNI6EACVNFQBWE74JDBB2PI5FSEMPMHQJSFZTLWO2XORDSIW6PV'
	network:        .testnet
	cache:          false
)!

// mut client := stellar.get_client(account_name:"default", network: .testnet)!
mut hash := client.add_trust_line(
	asset_code: 'TFT'
	issuer:     'GA47YZA3PKFUZMPLQ3B5F2E3CJIB57TGGU7SPCQT2WAEYKN766PWIMB3'
)!
println('hash: ${hash}')

mut hash2 := client.add_trust_line(
	asset_code: 'USDC'
	issuer:     'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5'
)!
println('hash2: ${hash2}')

// Make sell offer
sell_offer_args := stellar.OfferArgs{
	selling: stellar.Asset{
		asset_code: 'native'
		// issuer:     'GA47YZA3PKFUZMPLQ3B5F2E3CJIB57TGGU7SPCQT2WAEYKN766PWIMB3'
	}
	buying:  stellar.Asset{
		asset_code: 'TFT'
		issuer:     'GA47YZA3PKFUZMPLQ3B5F2E3CJIB57TGGU7SPCQT2WAEYKN766PWIMB3'
	}
	sell:    true
	amount:  50
	price:   10
}
mut sell_offer_id := client.create_offer(sell_offer_args)!

println('sell_offer_id: ${sell_offer_id}')

// Make buy offer
mut buy_offer_args := stellar.OfferArgs{
	selling: stellar.Asset{
		asset_code: 'native'
		// issuer:     'GA47YZA3PKFUZMPLQ3B5F2E3CJIB57TGGU7SPCQT2WAEYKN766PWIMB3'
	}
	buying:  stellar.Asset{
		asset_code: 'TFT'
		issuer:     'GA47YZA3PKFUZMPLQ3B5F2E3CJIB57TGGU7SPCQT2WAEYKN766PWIMB3'
	}
	buy:     true
	amount:  50
	price:   10
}

mut buy_offer_id := client.create_offer(buy_offer_args)!

println('buy_offer_id: ${buy_offer_id}')

buy_offer_args.amount = 100
client.update_offer(buy_offer_id, buy_offer_args)!
println('offer ${buy_offer_id} is update')


client.delete_offer(sell_offer_id, sell_offer_args)!
println('sell offer ${sell_offer_id} is deleted')