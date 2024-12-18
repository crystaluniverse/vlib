module dao

import time

// returns info about what result of order would be, but does not execute it
pub struct TradeInfo {
pub mut:
	currency       string
	tokenprice_usd f64
	orderprice_usd f64
	usd_before     f64
	usd_after      f64
	tokens_before  f64
	tokens_after   f64
}

// simulate a buy order and return info as follows:
// ARGS for the trade info
// {
// 	currency string
// 	account  &Account
// 	amount   f64
// }
//
// pub struct BuyOrderInfo {
// 	currency       string
// 	tokenprice_usd f64
// 	orderprice_usd f64
// 	usd_before     f64
// 	usd_after      f64
// 	tokens_before  f64
// 	tokens_after   f64
// }
// ```
pub fn (mut dao DAO) trade_info(args PoolTradeArgs) !TradeInfo {
	// TODO: we need to do decent check here that buy is possible, is there enough money on the accounts
	mut r := dao.pools_wallet_get(args.account, args.currency, true)!

	return TradeInfo{
		currency:       r.poolcur.currency
		tokenprice_usd: r.poolcur.usdprice_buy
		orderprice_usd: args.amount / r.poolcur.usdprice_buy
	}
	// TODO: need to fill in before & after
}

pub struct PoolTradeArgs {
	currency string
	account  &Account
	amount   f64
}

// this allows a user to buy a chose currency
// e.g. dao.buy(buy(currency:"tft", account:kristof, amount:1000)!
//		this means kristof is buying 1000 tft, this needs to come from his personal account, if not there will fail
// ARGS for the trade info
// {
// 	currency string
// 	account  &Account
// 	amount   f64
// }
//
// pub struct BuyOrderInfo {
// 	currency       string
// 	tokenprice_usd f64
// 	orderprice_usd f64
// 	usd_before     f64
// 	usd_after      f64
// 	tokens_before  f64
// 	tokens_after   f64
// }
pub fn (mut dao DAO) pool_trade_buy(args PoolTradeArgs) !TradeInfo {
	// TODO: this code is for sure broken, need to fix

	mut r := dao.pools_wallet_get(args.account, args.currency, true)!

	// TODO
	usdneeded := args.amount / r.poolcur.usdprice_buy // money as paid for by the customer, needs to be given to the pool in usd
	currencyreceive := args.amount // documentation purpose, is the currency the user is buying & amount

	// this should always be there, because has been initialized that way
	mut buyer_private_account_usd := r.poolusd.wallets_pool[args.account.address]
	buyer_private_account_usd.amount -= usdneeded

	for key, mut p in r.poolcur.wallets_pool {
		// TODO: need to do a check in advance that its possible maybe not enough money
		p.amount -= currencyreceive / p.poolpercentage // deduct the bought currency in percentage from all account wallets
		mut walletusd0 := r.poolusd.wallets_pool[key] // add the usd coming in to all the usd accounts in same percentage
		walletusd0.amount += usdneeded / p.poolpercentage
	}

	r.poolusd.calculate()!
	r.poolcur.calculate()!

	return lp.buy_info(args)
}

pub fn (mut dao DAO) pool_trade_sell(args PoolTradeArgs) !TradeInfo {
}
