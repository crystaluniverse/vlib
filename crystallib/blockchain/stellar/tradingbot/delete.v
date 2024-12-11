module tradingbot

import freeflowuniverse.crystallib.blockchain.stellar
import freeflowuniverse.crystallib.ui.console

fn (mut bot StellarTradingBot) delete_sell_offers(mut active_offers []stellar.OfferModel) ! {
	for mut offer in active_offers {
		bot.delete_offer(offer: offer, sell: true)!
	}
}

fn (mut bot StellarTradingBot) delete_buy_offers(mut active_offers []stellar.OfferModel) ! {
	for mut offer in active_offers {
		bot.delete_offer(offer: offer, buy: true)!
	}
}

@[params]
struct DeleteOfferArgs {
pub mut:
	offer stellar.OfferModel @[required]
	sell  bool
	buy   bool
}

fn (mut bot StellarTradingBot) delete_offer(args DeleteOfferArgs) ! {
	console.print_stderr('Deleting offer ${args.offer.id.u64()}')
	bot.sclient.delete_offer(args.offer.id.u64(), stellar.OfferArgs{
		amount:  0
		price:   args.offer.price.f32()
		selling: stellar.get_offer_asset_type(bot.selling_asset_type, bot.selling_asset_code,
			bot.selling_asset_issuer)
		buying:  stellar.get_offer_asset_type(bot.buying_asset_type, bot.buying_asset_code,
			bot.buying_asset_issuer)
		buy:     args.buy
		sell:    args.sell
	})!
}
