module tradingbot

import freeflowuniverse.crystallib.blockchain.stellar
import math

@[params]
struct SellHighArgs {
	order_book   stellar.OrderBook @[required]
	active_offer ?stellar.OfferModel
}

// Sell if price is above target
fn (mut bot StellarTradingBot) sell_high(args SellHighArgs) ! {
	mut asset_info := stellar.GetOfferAssetInfo{
		asset_type:   bot.selling_asset_type
		asset_code:   bot.selling_asset_code
		asset_issuer: bot.selling_asset_issuer
	}

	mut asset_balance := bot.get_asset_balance(asset_info)!
	log('Asset ${bot.selling_asset_code} balance: ${asset_balance}', true)

	if asset_balance <= bot.preserve {
		return error('Wallet does not have enough balance for asset ${bot.selling_asset_code} to make a new sell offer, current balance is ${asset_balance}.')
	}

	mut selling_price := bot.selling_target_price

	highest_price := stellar.fetch_highest_bid_price(args.order_book)!
	highest_price_float := f32(highest_price.n) / f32(highest_price.d)

	if highest_price_float <= bot.buying_target_price {
		log('The price is too low: ${highest_price_float} <= ${bot.buying_target_price}, Skipping...',
			true)
		return
	}

	if highest_price_float > bot.selling_target_price {
		selling_price = highest_price_float
	}

	spendable_balance := asset_balance - bot.preserve
	log('Spendable balance: ${spendable_balance}', true)

	mut amount := math.min(spendable_balance, bot.selling_amount)

	offer_args := stellar.OfferArgs{
		selling: stellar.get_offer_asset_type(bot.selling_asset_type, bot.selling_asset_code,
			bot.selling_asset_issuer)
		buying:  stellar.get_offer_asset_type(bot.buying_asset_type, bot.buying_asset_code,
			bot.buying_asset_issuer)
		amount:  u64(amount)
		sell:    true
		price:   f32(selling_price)
	}

	if active_offer := args.active_offer {
		// check if update is needed
		amount = round_to_precision(amount, 7)
		active_offer_amount := f64(round_to_precision(active_offer.amount.f64(), 7))
		active_offer_price := round_to_precision(active_offer.price.f64(), 7)
		selling_price = f64(round_to_precision(f64(selling_price), 7))

		log('active offer: price: ${active_offer_price} - amount: ${active_offer_amount}',
			true)
		log('selling price: ${selling_price} - amount: ${amount}', true)

		if active_offer_price == selling_price && active_offer_amount == amount {
			// don't need an update
			log('offer ${active_offer.id.int()} is up-to-date.', true)
			return
		}

		bot.sclient.update_offer(active_offer.id.u64(), offer_args)!
		log('Offer ${active_offer.id.int()} is updated', true)

		return
	} else {
		mut offer_id := bot.sclient.create_offer(offer_args)!
		log('Offer ${offer_id} is created', true)
		return
	}
}
