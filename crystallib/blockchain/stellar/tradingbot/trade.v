module tradingbot

import freeflowuniverse.crystallib.blockchain.stellar
import time
import freeflowuniverse.crystallib.ui.console

const poll_interval = 2 * time.second // Polling interval for bot operations

// Steps
// 1. Initialize the stellar bot using the wallet secret
// 2. Support a real-time checking to get the current price of a spacific token eg. XLM

@[params]
pub struct StellarTradingBotArgs {
pub mut:
	account_secret string @[required] // The account secret

	selling_asset_code   string // asset to sell
	selling_asset_issuer string
	selling_asset_type   string
	buying_asset_code    string // asset to buy
	buying_asset_issuer  string
	buying_asset_type    string

	selling_target_price f32                    @[required] // Your desired sell price
	selling_amount       f32
	buying_target_price  f32                    @[required] // Your desired buy price
	buying_amount        f32
	network              stellar.StellarNetwork = .testnet
}

// Initialize the bot
pub fn new(args_ StellarTradingBotArgs) !StellarTradingBot {
	mut args := args_
	if args.selling_asset_type == '' {
		args.selling_asset_type = determine_asset_type(args.selling_asset_code)
	}

	if args.buying_asset_type == '' {
		args.buying_asset_type = determine_asset_type(args.buying_asset_type)
	}

	if args.selling_target_price <= args.buying_target_price {
		return error('selling price must be strictly higher than buying price')
	}

	mut hclient := stellar.new_horizon_client(args.network)!
	mut sclient := stellar.new_client(
		account_name: 'tradingbot'
		account_secret: args.account_secret
		network: args.network
		cache: false
	)!

	account_keys := stellar.get_account_keys(args.account_secret)!

	mut bot := StellarTradingBot{
		hclient: hclient
		sclient: sclient
		account_secret: account_keys.secret
		account_address: account_keys.address
		selling_asset_type: args.selling_asset_type
		selling_asset_code: args.selling_asset_code
		selling_asset_issuer: args.selling_asset_issuer
		selling_amount: args.selling_amount
		selling_target_price: args.selling_target_price
		// selling: selling
		buying_target_price: args.buying_target_price
		buying_asset_code: args.buying_asset_code
		buying_asset_type: args.buying_asset_type
		buying_asset_issuer: args.buying_asset_issuer
		buying_amount: args.buying_amount
		// buying: buying
	}

	// bot.update_assets()
	bot.add_needed_trust_lines()!
	return bot
}

// // Determine the asset code and type
// fn (mut bot StellarTradingBot) update_assets() {
// 	if bot.selling_asset_type == 'native' {
// 		bot.selling_asset_code = 'native'
// 	}

// 	if bot.buying_asset_type == 'native' {
// 		bot.buying_asset_code = 'native'
// 	}

// 	println('bot: ${bot}')
// }

// Add trust lines for the assets
fn (mut bot StellarTradingBot) add_needed_trust_lines() ! {
	account := bot.hclient.get_account(bot.account_address)!

	mut need_selling_trustline, mut need_buying_trustline := bot.selling_asset_type != 'native', bot.buying_asset_type != 'native'
	for balance in account.balances {
		if balance.asset_type == bot.selling_asset_type
			&& balance.asset_code == bot.selling_asset_code
			&& balance.asset_issuer == bot.selling_asset_issuer {
			need_selling_trustline = false
		}

		if balance.asset_type == bot.buying_asset_type
			&& balance.asset_code == bot.buying_asset_code
			&& balance.asset_issuer == bot.buying_asset_issuer {
			need_buying_trustline = false
		}
	}

	if need_selling_trustline {
		println('Adding trustline for ${bot.selling_asset_code}, Issuer: ${bot.selling_asset_issuer}')
		bot.sclient.add_trust_line(
			asset_code: bot.selling_asset_code
			issuer: bot.selling_asset_issuer
		)!
	}

	if need_buying_trustline {
		println('Adding trustline for ${bot.buying_asset_code}, Issuer: ${bot.buying_asset_issuer}')
		bot.sclient.add_trust_line(
			asset_code: bot.buying_asset_code
			issuer: bot.buying_asset_issuer
		)!
	}
}

// Runs a specific operation (buy or sell) in a loop
pub fn (mut bot StellarTradingBot) run() ! {
	println('Bot status: selling ${bot.selling_asset_code}, buying ${bot.buying_asset_code}')

	mut active_offers := bot.fetch_wallet_offers()!

	if bot.selling_amount == 0 {
		bot.delete_sell_offers(active_offers)!
	}

	if bot.buying_amount == 0 {
		bot.delete_buy_offers(active_offers)!
	}

	if bot.selling_amount == 0 && bot.buying_amount == 0 {
		return
	}

	/*	
		TODO:
			- when fetching order book, exclude ours // maybe not needed
			- validate that buy threshold is strictly less than sell threshold
			- for sell, validate that fetched wallet offer is actually a sell offer by validating price is ess than or equal to sell threshold
			- for buy, validate that fetched wallet offer is actually a buy offer by validating price is less or equal to buy threshold
	*/
	for {
		active_offers = bot.fetch_wallet_offers()!

		order_book := bot.fetch_order_book() or {
			console.print_stderr('failed to get orderbook: ${err}')
			continue
		}

		bot.sell_high(active_offers, order_book) or { console.print_stderr('${err}') }
		bot.buy_low(active_offers, order_book) or { console.print_stderr('${err}') }

		// Adjust polling interval as needed
		time.sleep(tradingbot.poll_interval)
	}
}

// // Delete offer
// fn (mut bot StellarTradingBot) delete_offer(active_offer stellar.OfferModel) ! {
// 	println('Deleting offer with ID: ${active_offer.id}')

// 	mut active_offers := bot.fetch_wallet_offers()!
// 	println('Active offer: ${active_offer}')

// 	if active_offer.id.int() == 0 {
// 		return error('Cannot delete offer with ID: ${active_offer.id}')
// 	}

// 	mut selling_asset := stellar.Asset{
// 		asset_code: bot.selling_asset_code
// 		issuer: bot.selling_asset_issuer
// 	}

// 	mut buying_asset := stellar.Asset{
// 		asset_code: bot.buying_asset_code
// 		issuer: bot.buying_asset_issuer
// 	}

// 	if active_offer.selling.asset_type == 'native' {
// 		selling_asset.asset_code = 'native'
// 	}

// 	if active_offer.buying.asset_type == 'native' {
// 		buying_asset.asset_code = 'native'
// 	}

// 	mut delete_offer_args := stellar.OfferArgs{
// 		sell: true
// 		amount: u64(bot.amount)
// 		price: bot.selling_target_price
// 		selling: selling_asset
// 		buying: buying_asset
// 	}

// 	bot.sclient.delete_offer(active_offer.id.u64(), delete_offer_args)!
// 	println('Offer ${active_offer.id} is deleted')
// }

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

	order_book := bot.hclient.get_order_book(order_book_request) or {
		return error('Failed to fetch order book: ${err}')
	}
	println('Order Book: ${order_book}')
	return order_book
}

fn (mut bot StellarTradingBot) fetch_wallet_offers() ![]stellar.OfferModel {
	// if bot.account_address.len == 0 {
	// 	return error('Account address is empty')
	// }

	// // fix for native type XLM
	// mut buying_asset_code := ''
	// mut buying_asset_issuer := ''
	// mut selling_asset_code := ''
	// mut selling_asset_issuer := ''

	// if bot.buying_asset_code != 'XLM' {
	// 	buying_asset_code = bot.buying_asset_code
	// 	buying_asset_issuer = bot.buying_asset_issuer
	// }

	// if bot.selling_asset_code != 'XLM' {
	// 	selling_asset_code = bot.selling_asset_code
	// 	selling_asset_issuer = bot.selling_asset_issuer
	// }

	// Fetch offers from Horizon client
	mut offers_page := bot.hclient.get_offers(seller: bot.account_address, limit: 200)!

	// Filter offers to find the matching pair
	mut matching_offers := []stellar.OfferModel{}

	for mut offer in offers_page {
		// selling :=
		// if offer.selling.
		// offer.selling.asset_code = if offer.selling.asset_type == 'native' {
		// 	'native'
		// } else {
		// 	offer.selling.asset_code
		// }

		// offer.buying.asset_code = if offer.buying.asset_type == 'native' {
		// 	'native'
		// } else {
		// 	offer.buying.asset_code
		// }

		if offer.selling.asset_code == bot.selling_asset_code
			&& offer.selling.asset_issuer == bot.selling_asset_issuer
			&& offer.selling.asset_type == bot.selling_asset_type
			&& offer.buying.asset_code == bot.buying_asset_code
			&& offer.buying.asset_issuer == bot.buying_asset_issuer
			&& offer.buying.asset_type == bot.buying_asset_type {
			matching_offers << offer
		}
	}

	return matching_offers
}

fn (mut bot StellarTradingBot) get_asset_balance(asset stellar.GetOfferAssetInfo) !f64 {
	account := bot.hclient.get_account(bot.account_address)!

	for balance_info in account.balances {
		if asset.asset_type == 'native' && balance_info.asset_type == 'native' {
			return balance_info.balance.f64()
		}

		if balance_info.asset_code == asset.asset_code
			&& balance_info.asset_issuer == asset.asset_issuer
			&& asset.asset_type == balance_info.asset_type {
			return balance_info.balance.f64()
		}
	}

	return error('account does not have trust line for asset ${asset.asset_code}')
}

fn (mut bot StellarTradingBot) match_sell_asset(asset_type string, asset_code string, asset_issuer string) bool {
	return (bot.selling_asset_type == 'native' && asset_type == 'native')
		|| (bot.selling_asset_type == asset_type && bot.selling_asset_code == asset_code
		&& bot.selling_asset_issuer == asset_issuer)
}

fn (mut bot StellarTradingBot) match_buy_asset(asset_type string, asset_code string, asset_issuer string) bool {
	return (bot.buying_asset_type == 'native' && asset_type == 'native')
		|| (bot.buying_asset_type == asset_type && bot.buying_asset_code == asset_code
		&& bot.buying_asset_issuer == asset_issuer)
}

// fn (mut bot StellarTradingBot) create_offer(op StellarTradingBotOperation, order_book stellar.OrderBook, active_offer stellar.OfferModel) ! {
// 	println('Creating a new offer')

// 	mut asset_info := stellar.GetOfferAssetInfo{}
// 	mut highest_price := stellar.Price{}
// 	// mut threshold_price := stellar.get_offer_price(bot.buying_target_price)

// 	match op {
// 		.sell {
// 			asset_info.asset_type = bot.selling_asset_type
// 			asset_info.asset_code = bot.selling_asset_code
// 			asset_info.asset_issuer = bot.selling_asset_issuer
// 			highest_price = stellar.fetch_highest_bid_price(order_book)!
// 			highest_price_float := f64(highest_price.n) / f64(highest_price.d)
// 			if highest_price_float > bot.selling_target_price {
// 				threshold_price = highest_price
// 			}
// 		}
// 		.buy {
// 			asset_info.asset_type = bot.buying_asset_type
// 			asset_info.asset_code = bot.buying_asset_code
// 			asset_info.asset_issuer = bot.buying_asset_issuer
// 			highest_price = stellar.fetch_highest_ask_price(order_book)!
// 			highest_price_float := f64(highest_price.n) / f64(highest_price.d)
// 			if highest_price_float > bot.buying_target_price {
// 				threshold_price = highest_price
// 			}
// 		}
// 	}

// 	asset_balance := bot.get_asset_balance(asset_info)!
// 	// create new offer
// 	if bot.amount == 0 {
// 		return error('The amount is 0, but There are no active offers to delete.')
// 	}

// 	if asset_balance <= bot.preserve {
// 		return error('Wallet does not have enough balance for a new offer, current balance is ${asset_balance}.')
// 	}

// 	println('there is no active offer for wallet and configured pair: (${bot.buying_asset_code} - ${bot.selling_asset_code})')

// 	spendable_balance := asset_balance - bot.preserve
// 	println('Spendable balance: ${spendable_balance}')

// 	amount := math.min(spendable_balance, bot.amount)

// 	// Make buy offer
// 	mut selling_asset := stellar.Asset{
// 		asset_code: bot.selling_asset_code
// 		issuer: bot.selling_asset_issuer
// 	}

// 	mut buying_asset := stellar.Asset{
// 		asset_code: bot.buying_asset_code
// 		issuer: bot.buying_asset_issuer
// 	}

// 	if active_offer.selling.asset_type == 'native' {
// 		selling_asset.asset_code = 'native'
// 	}

// 	if active_offer.buying.asset_type == 'native' {
// 		buying_asset.asset_code = 'native'
// 	}

// 	offer_args := stellar.OfferArgs{
// 		selling: selling_asset
// 		buying: buying_asset
// 		amount: u64(amount)
// 		buy: if op == .buy { true } else { false }
// 		sell: if op == .sell { true } else { false }
// 		price: if op == .buy { bot.buying_target_price } else { bot.selling_target_price }
// 	}

// 	mut offer_id := bot.sclient.create_offer(offer_args)!
// 	println('Offer ${offer_id} is created')
// }

// fn (mut bot StellarTradingBot) update_offer(op StellarTradingBotOperation, order_book stellar.OrderBook, active_offer stellar.OfferModel) ! {
// 	// TODO: check if buy or sell
// 	mut selling_asset := stellar.Asset{
// 		asset_code: bot.selling_asset_code
// 		issuer: bot.selling_asset_issuer
// 	}

// 	mut buying_asset := stellar.Asset{
// 		asset_code: bot.buying_asset_code
// 		issuer: bot.buying_asset_issuer
// 	}

// 	if active_offer.selling.asset_type == 'native' {
// 		selling_asset.asset_code = 'native'
// 	}

// 	if active_offer.buying.asset_type == 'native' {
// 		buying_asset.asset_code = 'native'
// 	}

// 	offer_args := stellar.OfferArgs{
// 		selling: selling_asset
// 		buying: buying_asset
// 		amount: u64(bot.amount)
// 		buy: if op == .buy { true } else { false }
// 		sell: if op == .sell { true } else { false }
// 		price: if op == .buy { bot.buying_target_price } else { bot.selling_target_price }
// 	}

// 	bot.sclient.update_offer(active_offer.id.u64(), offer_args)!
// 	println('Offer ${active_offer.id} is updated')
// }
