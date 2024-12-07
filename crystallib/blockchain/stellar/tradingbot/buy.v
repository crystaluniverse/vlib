module tradingbot

import freeflowuniverse.crystallib.blockchain.stellar

// Buy if price is below target
fn (mut bot StellarTradingBot) buy_low(active_offers []stellar.OfferModel, order_book stellar.OrderBook) ! {
	mut active_buy_offer := bot.get_buy_offer_from_active_offers(active_offers) or {
		return error('failed to get active buy offer: ${err}')
	}

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
