module tradingbot

import freeflowuniverse.crystallib.blockchain.stellar
import math

// Sell if price is above target
fn (mut bot StellarTradingBot) sell_high(active_offers []stellar.OfferModel, order_book stellar.OrderBook) ! {
	mut active_sell_offer := bot.get_sell_offer_from_active_offers(active_offers) or {
		return error('failed to get active sell offer: ${err}')
	}

	bot.create_or_update_sell_offer(active_sell_offer, order_book)!
}

fn (mut bot StellarTradingBot) get_sell_offer_from_active_offers(active_offers []stellar.OfferModel) !stellar.OfferModel {
	mut matching_offer := stellar.OfferModel{}
	for offer in active_offers {
		if bot.is_sell_offer(offer) {
			// this is a sell offer
			if matching_offer.id.int() != 0 {
				return error('there is more than one sell offer in wallet active offers')
			}

			matching_offer = offer
		}
	}

	return matching_offer
}

fn (mut bot StellarTradingBot) is_sell_offer(offer stellar.OfferModel) bool {
	return
		bot.match_sell_asset(offer.selling.asset_type, offer.selling.asset_code, offer.selling.asset_issuer)
		&& bot.match_buy_asset(offer.buying.asset_type, offer.buying.asset_code, offer.buying.asset_issuer)
}

fn (mut bot StellarTradingBot) create_or_update_sell_offer(active_offer stellar.OfferModel, order_book stellar.OrderBook) !u64 {
	println('Creating/Updating a new sell offer')

	mut asset_info := stellar.GetOfferAssetInfo{
		asset_type:   bot.selling_asset_type
		asset_code:   bot.selling_asset_code
		asset_issuer: bot.selling_asset_issuer
	}

	mut selling_price := bot.selling_target_price

	highest_price := stellar.fetch_highest_bid_price(order_book)!

	highest_price_float := f32(highest_price.n) / f32(highest_price.d)
	if highest_price_float > bot.selling_target_price {
		selling_price = highest_price_float
	}

	mut asset_balance := bot.get_asset_balance(asset_info)!
	println('Asset balance: ${asset_balance}')

	if asset_balance <= bot.preserve {
		return error('Wallet does not have enough balance for asset ${bot.selling_asset_code} to make a new sell offer, current balance is ${asset_balance}.')
	}

	spendable_balance := asset_balance - bot.preserve
	println('Spendable balance: ${spendable_balance}')

	println('bot.selling_amount: ${bot.selling_amount}')
	mut amount := math.min(spendable_balance, bot.selling_amount)
	println('amount: ${amount}')

	offer_args := stellar.OfferArgs{
		selling: stellar.get_offer_asset_type(bot.selling_asset_type, bot.selling_asset_code,
			bot.selling_asset_issuer)
		buying:  stellar.get_offer_asset_type(bot.buying_asset_type, bot.buying_asset_code,
			bot.buying_asset_issuer)
		amount:  u64(amount)
		sell:    true
		price:   f32(selling_price)
	}

	if active_offer.id.int() == 0 {
		mut offer_id := bot.sclient.create_offer(offer_args)!
		println('Offer ${offer_id} is created')

		return offer_id
	}

	// check if update is needed
	amount = round_to_precision(amount, 7)
	active_offer_amount := active_offer.amount.f64()
	active_offer_price := round_to_precision(active_offer.price.f64(), 7)
	selling_price = f64(round_to_precision(f64(selling_price), 7))

	println('active offer:  price: ${active_offer_price} - amount: ${active_offer_amount}')
	println('selling: price: ${selling_price} - amount: ${amount}')

	if active_offer_price == selling_price && active_offer_amount == amount {
		// don't need an update
		println('offer ${active_offer.id.int()} is up-to-date.')
		return active_offer.id.u64()
	}

	bot.sclient.update_offer(active_offer.id.u64(), offer_args)!
	println('Offer ${active_offer.id.int()} is updated')

	return active_offer.id.u64()
}
