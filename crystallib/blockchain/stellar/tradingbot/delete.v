module tradingbot

import freeflowuniverse.crystallib.blockchain.stellar

fn (mut bot StellarTradingBot) delete_sell_offers(active_offers []stellar.OfferModel) ! {
	for offer in active_offers {
		if !bot.is_sell_offer(offer) {
			continue
		}

		println('Deleting offer ${offer.id.u64()}')
		bot.sclient.delete_offer(offer.id.u64(), stellar.OfferArgs{
			amount: 0
			price: offer.price.f32()
			selling: stellar.get_offer_asset_type(bot.selling_asset_type, bot.selling_asset_code,
				bot.selling_asset_issuer)
			buying: stellar.get_offer_asset_type(bot.buying_asset_type, bot.buying_asset_code,
				bot.buying_asset_issuer)
			sell: true
		})!
	}
}

fn (mut bot StellarTradingBot) delete_buy_offers(active_offers []stellar.OfferModel) ! {
	for offer in active_offers {
		println('check delete buy offer: ${offer}')
		if !bot.is_buy_offer(offer) {
			continue
		}

		println('Deleting offer ${offer.id.u64()}')
		bot.sclient.delete_offer(offer.id.u64(), stellar.OfferArgs{
			amount: 0
			price: offer.price.f32()
			selling: stellar.get_offer_asset_type(bot.selling_asset_type, bot.selling_asset_code,
				bot.selling_asset_issuer)
			buying: stellar.get_offer_asset_type(bot.buying_asset_type, bot.buying_asset_code,
				bot.buying_asset_issuer)
			buy: true
		})!
	}
}
