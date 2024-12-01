module tradingbot

import freeflowuniverse.crystallib.blockchain.stellar
import time

// Steps
// 1. Initialize the stellar bot using the wallet secret
// 2. Support a real-time checking to get the current price of a spacific token eg. XLM

pub struct StellarTradingBot {
mut:
	hclient stellar.HorizonClient // Horizon client
	sclient stellar.StellarClient // Stellar client
pub mut:
	account_secret       string
	selling_asset_code   string
	buying_asset_code    string
	buying_target_price  string
	selling_target_price string
	selling_asset_issuer string
	buying_asset_issuer  string
	selling_asset_type   string
	buying_asset_type    string
	// TODO: add sell amount
	// TODO: add buy amount
}

@[params]
pub struct StellarTradingBotArgs {
pub mut:
	account_secret       string                 @[required] // The account secret
	buying_target_price  string                 @[required] // Your desired buy price
	selling_target_price string                 @[required] // Your desired sell price
	selling_asset_code   string                 @[required]
	buying_asset_code    string                 @[required]
	selling_asset_issuer string
	buying_asset_issuer  string
	network              stellar.StellarNetwork = .testnet
}

pub fn new(args StellarTradingBotArgs) !StellarTradingBot {
	mut hclient := stellar.new_horizon_client(args.network)!
	mut sclient := stellar.new_client(
		account_name: 'default'
		account_secret: args.account_secret
		network: args.network
		cache: false
	)!

	// TODO: i believe any asset can work, no?
	mut supported_issuers := {
		'TFT': 'GA47YZA3PKFUZMPLQ3B5F2E3CJIB57TGGU7SPCQT2WAEYKN766PWIMB3'
		'XLM': 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5'
	}

	mut tbot := StellarTradingBot{
		hclient: hclient
		sclient: sclient
		selling_target_price: args.selling_target_price
		selling_asset_code: args.selling_asset_code
		buying_target_price: args.buying_target_price
		buying_asset_code: args.buying_asset_code
		account_secret: args.account_secret
	}

	if args.selling_asset_code.to_upper() in supported_issuers.keys() {
		tbot.selling_asset_issuer = supported_issuers[args.selling_asset_code]
	} else {
		tbot.selling_asset_issuer = args.selling_asset_issuer
		if tbot.selling_asset_issuer.len == 0 {
			return error('Invalid selling asset issuer. Asset code is ${args.selling_asset_code}')
		}
		println('Adding trustline for ${args.selling_asset_code}, Issuer: ${args.selling_asset_issuer}')
		// TODO: Need to check if the trust line already exists
		tx_hash := sclient.add_trust_line(
			asset_code: tbot.selling_asset_code
			issuer: tbot.selling_asset_issuer
		)!
		println('Transaction hash: ${tx_hash}')
	}

	if args.buying_asset_code.to_upper() in supported_issuers.keys() {
		tbot.buying_asset_issuer = supported_issuers[args.buying_asset_code]
	} else {
		tbot.buying_asset_issuer = args.buying_asset_issuer
		if tbot.buying_asset_issuer.len == 0 {
			return error('Invalid buying asset issuer. Asset code is ${args.buying_asset_code}')
		}
		println('Adding trustline for ${args.buying_asset_code}, Issuer: ${args.buying_asset_issuer}')
		// TODO: Need to check if the trust line already exists
		tx_hash := sclient.add_trust_line(
			asset_code: tbot.buying_asset_code
			issuer: tbot.buying_asset_issuer
		)!
		println('Transaction hash: ${tx_hash}')
	}

	// Determine the asset types
	mut selling_asset_type := 'native'
	if args.selling_asset_code != 'XLM' {
		selling_asset_type = if args.selling_asset_code.len <= 4 {
			'credit_alphanum4'
		} else {
			'credit_alphanum12'
		}
	}

	mut buying_asset_type := 'native'
	if args.buying_asset_code != 'XLM' {
		buying_asset_type = if args.buying_asset_code.len <= 4 {
			'credit_alphanum4'
		} else {
			'credit_alphanum12'
		}
	}

	tbot.selling_asset_type = selling_asset_type
	tbot.buying_asset_type = buying_asset_type

	return tbot
}

enum StellarTradingBotOperation {
	sell
	buy
}

pub fn (mut bot StellarTradingBot) run_buy_and_sell() ! {
	// Spawn the buy operation
	// spawn bot.run(.buy)
	// Spawn the sell operation
	// spawn bot.run(.sell)
	bot.run(.sell)!
}

pub fn (mut bot StellarTradingBot) run_buy() ! {
	// Spawn the buy operation
	spawn bot.run(.buy)
}

pub fn (mut bot StellarTradingBot) run_sell() ! {
	// Spawn the sell operation
	spawn bot.run(.sell)
}

// Runs a specific operation (buy or sell) in a loop
fn (mut bot StellarTradingBot) run(op StellarTradingBotOperation) ! {
	println('Bot status: selling ${bot.selling_asset_code}, buying ${bot.buying_asset_code}')
	for {
		match op {
			.buy { bot.try_buy() or { eprintln('Error during buy operation: ${err}') } }
			.sell { bot.try_sell() or { eprintln('Error during sell operation: ${err}') } }
		}
		time.sleep(2 * time.second) // Adjust polling interval as needed
	}
}

// Fetch order book
fn (mut bot StellarTradingBot) fetch_order_book() !stellar.OrderBook {
	mut order_book_request := stellar.OrderBookRequest{
		selling_asset_code: bot.selling_asset_code
		selling_asset_type: bot.selling_asset_type
		buying_asset_code: bot.buying_asset_code
		buying_asset_type: bot.buying_asset_type
		selling_asset_issuer: bot.selling_asset_issuer
		buying_asset_issuer: bot.buying_asset_issuer
		limit: 200
	}

	println('Order book request: ${order_book_request}')
	order_book := bot.hclient.get_order_book(order_book_request) or {
		return error('Failed to fetch order book: ${err}')
	}
	println('Order Book: ${order_book}')
	return order_book
}

// Buy if price is below target
fn (mut bot StellarTradingBot) try_buy() ! {
	order_book := bot.fetch_order_book()!
	if order_book.asks.len > 0 {
		best_ask := order_book.asks[0] // Lowest sell price
		if best_ask.price.f64() <= bot.buying_target_price.f64() {
			println('Buying at price: ${best_ask.price}')
			// Make buy offer
			mut buy_offer_args := stellar.OfferArgs{
				selling: stellar.Asset{
					asset_code: 'native'
					// issuer:     'GA47YZA3PKFUZMPLQ3B5F2E3CJIB57TGGU7SPCQT2WAEYKN766PWIMB3'
				}
				buying: stellar.Asset{
					asset_code: 'TFT'
					issuer: 'GA47YZA3PKFUZMPLQ3B5F2E3CJIB57TGGU7SPCQT2WAEYKN766PWIMB3'
				}
				buy: true
				amount: 50
				price: 10
			}

			mut buy_offer_id := bot.sclient.create_offer(buy_offer_args)!

			println('buy_offer_id: ${buy_offer_id}')
			// TODO: We need to think if the bot should wait for the offer to be accepted
			// TODO: We need to think if we should continue selling if the offer is not accepted
			// TODO: We need to think if we should return and exit the loop
		}
	}
}

// Sell if price is above target
fn (mut bot StellarTradingBot) try_sell() ! {
	// TODO: fetch current offers if any
	/*
		notes:
			- assume bot works on one offer only
			- if there is an active offer, update it accordingly
	*/
	order_book := bot.fetch_order_book()!
	if order_book.bids.len > 0 {
		best_bid := order_book.bids[0] // Highest buy price
		if best_bid.price.f64() >= bot.selling_target_price.f64() {
			println('Selling at price: ${best_bid.price}')
			// Make sell offer
			sell_offer_args := stellar.OfferArgs{
				selling: stellar.Asset{
					asset_code: 'native'
					// issuer:     'GA47YZA3PKFUZMPLQ3B5F2E3CJIB57TGGU7SPCQT2WAEYKN766PWIMB3'
				}
				buying: stellar.Asset{
					asset_code: 'TFT'
					issuer: 'GA47YZA3PKFUZMPLQ3B5F2E3CJIB57TGGU7SPCQT2WAEYKN766PWIMB3'
				}
				sell: true
				amount: 50
				price: 10
			}
			mut sell_offer_id := bot.sclient.create_offer(sell_offer_args)!
			println('Sell offer id: ${sell_offer_id}')
			// TODO: We need to think if the bot should wait for the offer to be accepted
			// TODO: We need to think if we should continue selling if the offer is not accepted
			// TODO: We need to think if we should return and exit the loop
		}

		// TODO: if amount = 0, delete offer if exists
	}
}
