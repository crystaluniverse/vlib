module tradingbot

import freeflowuniverse.crystallib.blockchain.stellar
import time

// Steps
// 1. Initialize the stellar bot using the wallet secret
// 2. Support a real-time checking to get the current price of a spacific token eg. XLM

@[params]
pub struct StellarTradingBotArgs {
pub mut:
	account_secret       string @[required] // The account secret
	buying_target_price  string @[required] // Your desired buy price
	selling_target_price string @[required] // Your desired sell price
	selling_asset_code   string @[required] // asset to sell
	buying_asset_code    string @[required] // asset to buy
	sell_amount          string // amount to sell
	buy_amount           string // amount to buy
	selling_asset_issuer string
	buying_asset_issuer  string
	network              stellar.StellarNetwork = .testnet
}

pub fn new(args StellarTradingBotArgs) !StellarTradingBot {
	// Validate asset issuers and normalize asset codes
	mut args_ := normalize_assets(args)!

	// Initialize Stellar clients
	mut hclient := stellar.new_horizon_client(args_.network)!
	mut sclient := stellar.new_client(
		account_name:   'tradingbot'
		account_secret: args_.account_secret
		network:        args_.network
		cache:          false
	)!

	// Retrieve account keys
	account_keys := stellar.get_account_keys(args_.account_secret)!

	// Construct trading bot
	mut tbot := StellarTradingBot{
		hclient:              hclient
		sclient:              sclient
		selling_target_price: args_.selling_target_price.f32()
		selling_asset_code:   args_.selling_asset_code
		buying_target_price:  args_.buying_target_price.f32()
		buying_asset_code:    args_.buying_asset_code
		account_secret:       account_keys.secret
		account_address:      account_keys.address
		selling_asset_issuer: args_.selling_asset_issuer
		buying_asset_issuer:  args_.buying_asset_issuer
		sell_amount:          args_.sell_amount.f64()
		buy_amount:           args_.buy_amount.f64()
		selling_asset_type:   determine_asset_type(args_.selling_asset_code, args_.selling_asset_issuer)
		buying_asset_type:    determine_asset_type(args_.buying_asset_code, args_.buying_asset_issuer)
	}

	// Add trust lines for both assets
	if tbot.selling_asset_type != 'native' {
		add_trust_line(mut tbot.sclient, tbot.selling_asset_code, tbot.selling_asset_issuer)!
	}

	if tbot.buying_asset_type != 'native' {
		add_trust_line(mut tbot.sclient, tbot.buying_asset_code, tbot.buying_asset_issuer)!
	}

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
			.buy { bot.try_buy() or { return error('Error during buy operation: ${err}') } }
			.sell { bot.try_sell() or { return error('Error during sell operation: ${err}') } }
		}
		time.sleep(2 * time.second) // Adjust polling interval as needed
	}
}

// Fetch order book
fn (mut bot StellarTradingBot) fetch_order_book() !stellar.OrderBook {
	mut order_book_request := stellar.OrderBookRequest{
		selling_asset_code:   bot.selling_asset_code
		selling_asset_type:   bot.selling_asset_type
		buying_asset_code:    bot.buying_asset_code
		buying_asset_type:    bot.buying_asset_type
		selling_asset_issuer: bot.selling_asset_issuer
		buying_asset_issuer:  bot.buying_asset_issuer
		limit:                200
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
		if best_ask.price.f32() <= bot.buying_target_price {
			println('Buying at price: ${best_ask.price}')
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

			mut buy_offer_id := bot.sclient.create_offer(buy_offer_args)!

			println('buy_offer_id: ${buy_offer_id}')
			// TODO: We need to think if the bot should wait for the offer to be accepted
			// TODO: We need to think if we should continue selling if the offer is not accepted
			// TODO: We need to think if we should return and exit the loop
		}
	}
}

// Sell if price is above target
fn (mut bot StellarTradingBot) try_sell() !f64 {
	// TODO: fetch current offers if any
	/*
		notes:
			- assume bot works on one offer only
			- if there is an active offer, update it accordingly
	*/
	order_book := bot.fetch_order_book()!
	highest_bid_price := stellar.fetch_highest_bid_price(order_book)!
	mut threshold_price := stellar.get_offer_price(bot.selling_target_price)
	highest_bid_float := f64(highest_bid_price.n) / f64(highest_bid_price.d)

	// get wallet balance
	asset_info := stellar.GetOfferAssetInfo{
		asset_type:   bot.selling_asset_type
		asset_code:   bot.selling_asset_code
		asset_issuer: bot.selling_asset_issuer
	}
	selling_asset_balance := bot.get_asset_balance(asset_info)!

	// get wallet offers
	mut active_offer := bot.fetch_wallet_offers()!
	println('Active offer: ${active_offer}')

	if active_offer.id.int() == 0 {
		// create new offer
		if bot.sell_amount == 0 {
			return error('Sell amount is 0, but There are no active offers to delete.')
		}

		if selling_asset_balance <= bot.preserve {
			return error('Wallet does not have enough balance for a new offer, current balance is ${selling_asset_balance}.')
		}

		println('there is no active offer for wallet and configured pair: (${bot.selling_asset_code} - ${bot.buying_asset_code})')

		if highest_bid_float > bot.selling_target_price {
			threshold_price = highest_bid_price
		}

		balance_diff := selling_asset_balance - bot.preserve
		println('Spendable balance: ${balance_diff}')

		// Make sell offer
		println('Creating sell offer')
		sell_offer_args := stellar.OfferArgs{
			selling: stellar.Asset{
				asset_code: bot.selling_asset_code
				issuer:     bot.selling_asset_issuer
			}
			buying:  stellar.Asset{
				asset_code: bot.buying_asset_code
				issuer:     bot.buying_asset_issuer
			}
			sell:    true
			amount:  u64(bot.sell_amount)
			price:   bot.selling_target_price
		}
		mut sell_offer_id := bot.sclient.create_offer(sell_offer_args)!
		println('Offer ${sell_offer_id} is created')
		return sell_offer_id
	}

	// TODO: Update offer if the offer ID is 0
	if bot.sell_amount == 0 {
		// Make buy offer
		println('Deleting offer with ID: ${active_offer.id}')
		mut selling_asset := stellar.Asset{
			asset_code: bot.selling_asset_code
			issuer:     bot.selling_asset_issuer
		}

		mut buying_asset := stellar.Asset{
			asset_code: bot.buying_asset_code
			issuer:     bot.buying_asset_issuer
		}

		if active_offer.selling.asset_type == 'native' {
			selling_asset.asset_code = 'native'
		}

		if active_offer.buying.asset_type == 'native' {
			buying_asset.asset_code = 'native'
		}

		mut delete_offer_args := stellar.OfferArgs{
			sell:    true
			amount:  u64(bot.sell_amount)
			price:   bot.selling_target_price
			selling: selling_asset
			buying:  buying_asset
		}

		bot.sclient.delete_offer(active_offer.id.u64(), delete_offer_args)!
		println('Offer ${active_offer.id} is deleted')
	}
	return 0
}

fn (mut bot StellarTradingBot) fetch_wallet_offers() !stellar.OfferModel {
	if bot.account_address.len == 0 {
		return error('Account address is empty')
	}

	// Fetch offers from Horizon client
	mut offers_page := bot.hclient.get_offers(seller: bot.account_address, limit: 200)!

	// Filter offers to find the matching pair
	mut matching_offer := stellar.OfferModel{}
	for mut offer in offers_page {
		offer.selling.asset_code = if offer.selling.asset_type == 'native' {
			'XLM'
		} else {
			offer.selling.asset_code
		}
		offer.buying.asset_code = if offer.buying.asset_type == 'native' {
			'XLM'
		} else {
			offer.buying.asset_code
		}

		if bot.is_matching_offer(offer) {
			// Ensure only one matching offer exists
			// TODO: What should we do if there is an active offer?
			if matching_offer.id.int() != 0 {
				return offer
				// return error('Wallet has more than one offer for the configured pair')
			}

			// Update the matching offer
			matching_offer = offer
		}
	}

	return matching_offer
}

// Checks if an offer matches the bot's configured pair
fn (mut bot StellarTradingBot) is_matching_offer(offer stellar.OfferModel) bool {
	return offer.selling.asset_code == bot.selling_asset_code
		&& offer.selling.asset_issuer == bot.selling_asset_issuer
		&& offer.selling.asset_type == bot.selling_asset_type
		&& offer.buying.asset_code == bot.buying_asset_code
		&& offer.buying.asset_type == bot.buying_asset_type
		&& offer.buying.asset_issuer == bot.buying_asset_issuer
}

fn (mut bot StellarTradingBot) get_asset_balance(asset stellar.GetOfferAssetInfo) !f64 {
	account := bot.hclient.get_account(bot.account_address)!

	for balance_info in account.balances {
		if asset.asset_type == 'native' && balance_info.asset_type == 'native' {
			println('balance_info: ${balance_info}')
			return balance_info.balance.f64()
		}

		if balance_info.asset_code == asset.asset_code
			&& balance_info.asset_issuer == asset.asset_issuer
			&& asset.asset_type == balance_info.asset_type {
			println('balance_info: ${balance_info}')
			return balance_info.balance.f64()
		}
	}

	return error('account does not have trust line for asset ${asset.asset_code}')
}
