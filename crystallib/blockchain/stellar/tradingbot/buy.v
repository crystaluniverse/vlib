module tradingbot

import freeflowuniverse.crystallib.blockchain.stellar
import math

// Buy if price is below target
fn (mut bot StellarTradingBot) buy_low(active_offers []stellar.OfferModel, order_book stellar.OrderBook) ! {
	mut active_buy_offer := bot.get_buy_offer_from_active_offers(active_offers) or {
		return error('failed to get active buy offer: ${err}')
	}

	bot.create_or_update_buy_offer(active_buy_offer, order_book)!

	// println('Active offer: ${active_buy_offer}')

	// if active_offer.id.int() == 0 {
	// 	// create new offer
	// 	bot.create_offer(.buy, order_book, active_offer)!
	// } else {
	// 	// update offer
	// 	bot.update_offer(.buy, order_book, active_offer)!
	// }

	// return order_book
}

// checks if offer has reversed assets (buy is sell, and sell is buy)
fn (mut bot StellarTradingBot) is_buy_offer(offer stellar.OfferModel) bool {
	return
		bot.match_buy_asset(offer.selling.asset_type, offer.selling.asset_code, offer.selling.asset_issuer)
		&& bot.match_buy_asset(offer.buying.asset_type, offer.buying.asset_code, offer.buying.asset_issuer)
}

fn (mut bot StellarTradingBot) get_buy_offer_from_active_offers(active_offers []stellar.OfferModel) !stellar.OfferModel {
	mut matching_offer := stellar.OfferModel{}
	for offer in active_offers {
		if bot.is_buy_offer(offer) {
			// this is a buy offer
			if matching_offer.id.int() != 0 {
				return error('there is more than one buy offer in wallet active offers')
			}

			matching_offer = offer
		}
	}

	return matching_offer
}

fn (mut bot StellarTradingBot) create_or_update_buy_offer(active_offer stellar.OfferModel, order_book stellar.OrderBook) !u64 {
	println('Creating/Updating a new buy offer')

	mut asset_info := stellar.GetOfferAssetInfo{
		asset_type:   bot.buying_asset_type
		asset_code:   bot.buying_asset_code
		asset_issuer: bot.buying_asset_issuer
	}

	mut buying_price := bot.buying_target_price
	highest_price := stellar.fetch_highest_bid_price(order_book)!

	highest_price_float := f32(highest_price.n) / f32(highest_price.d)
	if highest_price_float > bot.buying_target_price {
		buying_price = highest_price_float
	}

	asset_balance := bot.get_asset_balance(asset_info)!
	if asset_balance <= bot.preserve {
		return error('Wallet does not have enough balance for asset ${bot.buying_asset_code} to make a new buy offer, current balance is ${asset_balance}.')
	}

	mut spendable_balance := asset_balance - bot.preserve
	spendable_balance = spendable_balance / 10000000
	println('Spendable balance: ${spendable_balance}')

	mut amount := math.min(spendable_balance, bot.buying_amount)

	offer_args := stellar.OfferArgs{
		selling: stellar.get_offer_asset_type(bot.buying_asset_type, bot.buying_asset_code,
			bot.buying_asset_issuer)
		buying:  stellar.get_offer_asset_type(bot.selling_asset_type, bot.selling_asset_code,
			bot.selling_asset_issuer)
		amount:  u64(amount)
		sell:    true
		price:   buying_price
	}

	if active_offer.id.int() == 0 {
		mut offer_id := bot.sclient.create_offer(offer_args)!
		println('Offer ${offer_id} is created')

		return offer_id
	}

	amount = round_to_precision(amount, 5)
	active_offer_amount := round_to_precision(active_offer.amount.f64(), 5)
	active_offer_price := round_to_precision(active_offer.price.f64(), 4)

	buying_price = f32(round_to_precision(f64(buying_price), 4))

	println('active offer:  price: ${active_offer_price} - amount: ${active_offer_amount}')
	println('selling: price: ${buying_price} - amount: ${amount}')
	if active_offer_price == buying_price && active_offer_amount == amount {
		// don't need an update
		println('offer ${active_offer.id.int()} is up-to-date.')
		return active_offer.id.u64()
	}

	bot.sclient.update_offer(active_offer.id.u64(), offer_args)!
	println('Offer ${active_offer.id.int()} is updated')

	return active_offer.id.u64()
}
