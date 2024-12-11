module tradingbot

import freeflowuniverse.crystallib.blockchain.stellar
import freeflowuniverse.crystallib.ui.console
import time

const poll_interval = 10 * time.second // Polling interval for bot operations

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

	selling_target_price f64                    @[required] // Your desired sell price
	selling_amount       f64
	buying_target_price  f64                    @[required] // Your desired buy price
	buying_amount        f64
	network              stellar.StellarNetwork = .testnet
}

// Initialize the bot
pub fn new(args_ StellarTradingBotArgs) !StellarTradingBot {
	console.print_header('Initializing trading bot...')
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
		buying_target_price: args.buying_target_price
		buying_asset_code: args.buying_asset_code
		buying_asset_type: args.buying_asset_type
		buying_asset_issuer: args.buying_asset_issuer
		buying_amount: args.buying_amount
	}

	// bot.update_assets()
	bot.add_needed_trust_lines()!
	return bot
}

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
		console.print_header('Adding trustline for ${bot.selling_asset_code}, Issuer: ${bot.selling_asset_issuer}')
		bot.sclient.add_trust_line(
			asset_code: bot.selling_asset_code
			issuer: bot.selling_asset_issuer
		)!
	}

	if need_buying_trustline {
		console.print_header('Adding trustline for ${bot.buying_asset_code}, Issuer: ${bot.buying_asset_issuer}')
		bot.sclient.add_trust_line(
			asset_code: bot.buying_asset_code
			issuer: bot.buying_asset_issuer
		)!
	}
}

// Runs a specific operation (buy or sell) in a loop
pub fn (mut bot StellarTradingBot) run() ! {
	mut selling_asset := bot.selling_asset_code
	mut buying_asset := bot.buying_asset_code

	if bot.selling_asset_type == 'native' {
		selling_asset = 'XLM'
	}

	if bot.buying_asset_type == 'native' {
		buying_asset = 'XLM'
	}

	console.print_header('Bot status: selling ${selling_asset}, buying ${buying_asset}')

	mut active_offers := bot.fetch_wallet_offers()!

	if bot.selling_amount == 0 {
		bot.delete_sell_offers(mut active_offers)!
	}

	if bot.buying_amount == 0 {
		bot.delete_buy_offers(mut active_offers)!
	}

	if bot.selling_amount == 0 && bot.buying_amount == 0 {
		return
	}

	for {
		active_offers = bot.fetch_wallet_offers()!

		if active_offers.len > 1 {
			return error('Wallet has more than one offer')
		}

		order_book := bot.fetch_order_book() or {
			console.print_stderr('failed to get orderbook: ${err}')
			continue
		}

		active_offer := fn (active_offers []stellar.OfferModel) ?stellar.OfferModel {
			if active_offers.len == 1 {
				return active_offers[0]
			} else {
				return none
			}
		}(active_offers)

		console.print_header('Sell high offer logs')
		bot.sell_high(active_offer: active_offer, order_book: order_book) or {
			console.print_stderr('${err}')
		}

		console.print_header('Buy low offer logs')
		bot.buy_low(active_offer: active_offer, order_book: order_book) or {
			console.print_stderr('${err}')
		}

		// Adjust polling interval as needed
		time.sleep(tradingbot.poll_interval)
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

	order_book := bot.hclient.get_order_book(order_book_request) or {
		return error('Failed to fetch order book: ${err}')
	}
	return order_book
}

fn (mut bot StellarTradingBot) fetch_wallet_offers() ![]stellar.OfferModel {
	// Fetch offers from Horizon client
	mut offers_page := bot.hclient.get_offers(seller: bot.account_address, limit: 200)!

	// Filter offers to find the matching pair
	mut matching_offers := []stellar.OfferModel{}

	for mut offer in offers_page {
		if offer.selling.asset_code == bot.selling_asset_code
			&& offer.selling.asset_issuer == bot.selling_asset_issuer
			&& offer.selling.asset_type == bot.selling_asset_type
			&& offer.buying.asset_code == bot.buying_asset_code
			&& offer.buying.asset_issuer == bot.buying_asset_issuer
			&& offer.buying.asset_type == bot.buying_asset_type {
			offer.amount = '${offer.amount.f64() * 1e7}'
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
