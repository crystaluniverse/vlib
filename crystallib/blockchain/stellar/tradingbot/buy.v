module tradingbot

import freeflowuniverse.crystallib.blockchain.stellar
import math

@[params]
struct BuyLowArgs {
	order_book   stellar.OrderBook   @[required]
	active_offer ?stellar.OfferModel
}

// Buy if price is below target
fn (mut bot StellarTradingBot) buy_low(args BuyLowArgs) ! {
	log('Creating/Updating a new buy offer', false)

	mut asset_info := stellar.GetOfferAssetInfo{
		asset_type: bot.buying_asset_type
		asset_code: bot.buying_asset_code
		asset_issuer: bot.buying_asset_issuer
	}

	asset_balance := bot.get_asset_balance(asset_info)!
	log('Asset ${bot.buying_asset_code} balance: ${asset_balance}', false)

	if asset_balance <= bot.preserve {
		return error('Wallet does not have enough balance for asset ${bot.buying_asset_code} to make a new buy offer, current balance is ${asset_balance}.')
	}

	mut buying_price := bot.buying_target_price
	lowest_price := stellar.fetch_lowest_ask_price(args.order_book) // 500

	lowest_price_float := f32(lowest_price.n) / f32(lowest_price.d)

	if lowest_price_float < bot.buying_target_price {
		buying_price = lowest_price_float
	}

	mut spendable_balance := asset_balance - bot.preserve
	log('Spendable balance: ${spendable_balance}', false)

	mut amount := math.min(spendable_balance, bot.buying_amount)

	offer_args := stellar.OfferArgs{
		selling: stellar.get_offer_asset_type(bot.buying_asset_type, bot.buying_asset_code,
			bot.buying_asset_issuer)
		buying: stellar.get_offer_asset_type(bot.selling_asset_type, bot.selling_asset_code,
			bot.selling_asset_issuer)
		amount: amount
		buy: true
		price: f32(buying_price)
	}

	if active_offer := args.active_offer {
		// check if update is needed
		amount = round_to_precision(amount, 7)
		active_offer_amount := f64(round_to_precision(active_offer.amount.f64(), 7))
		active_offer_price := round_to_precision(active_offer.price.f64(), 7)
		buying_price = f64(round_to_precision(f64(buying_price), 7))

		log('active offer:  price: ${active_offer_price} - amount: ${active_offer_amount}',
			false)
		log('buying: price: ${buying_price} - amount: ${amount}', false)

		if active_offer_price == buying_price && math.abs(active_offer_amount - amount) < 1e-7 {
			// don't need an update
			log('offer ${active_offer.id.int()} is up-to-date.', false)
			return
		}

		bot.sclient.update_offer(active_offer.id.u64(), offer_args)!
		log('Offer ${active_offer.id.int()} is updated', false)

		return
	} else {
		mut offer_result := bot.sclient.create_offer(offer_args)!
		if offer_result.claimed {
			log('Offer created and claimed by ${offer_result.offer_id}', false)
		} else {
			log('Offer ${offer_result.offer_id} is created', false)
		}

		return
	}
}
