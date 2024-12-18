module dao

import time
import freeflowuniverse.crystallib.core.texttools

// dao pools are done per currency
// they group money on behalf of users in the DAO
@[heap]
pub struct Pool {
pub mut:
	currency      string    // symbol of currency
	curvalue      f64       // how much of the currency is there
	usdprice_buy  f64       // what value do we buy the currency in usd
	usdprice_sell f64       // what value do we sell the currency in usd
	modtime       time.Time // timestamp of last calculation

	wallets_pool    map[string]&LPWallet // money kept for an account in pool, they key is the public key of account
	wallets_private map[string]&LPWallet // money kept for an account, not in pool, they key is the public key of account
}

// parameters relevant to a liquidity pool
pub struct LPParams {
pub mut:
	currency      string // e.g. usdc, tft, ...
	usdprice_buy  f64
	usdprice_sell f64
}

// set dao pool
pub fn (mut t DAO) pool_set(arg LPParams) !&Pool {
	if texttools.name_fix_no_underscore(arg.currency).to_lower() != arg.currency {
		return error('can specify currency only in lowercase and no special chars, e.g. tft, usdc, ... is ok')
	}
	if arg.currency in t.pools {
		// means the dao pool already exists, we need multisignature
		mut lp := t.pools[arg.currency]
		lp.currency = arg.currency
		lp.usdprice_sell = arg.usdprice_sell
		lp.usdprice_buy = arg.usdprice_buy
		lp.modtime = t.time_current
		// check that nothing weird is filled in
		asset_check(lp)!
		return lp
	}

	mut a := Pool{
		currency:      arg.currency
		usdprice_sell: arg.usdprice_sell
		usdprice_buy:  arg.usdprice_buy
		modtime:       t.time_current
	}
	asset_check(a)!

	t.pools[arg.currency] = &a

	return t.pools[arg.currency]
}

pub fn (mut t DAO) pool_get(currency string) !&Pool {
	if currency in t.pools {
		return t.pools[currency]
	}
	return error('Cannot find liquidity pool for currency ${currency}')
}

// will recalculate of all wallets
pub fn (mut lp Pool) calculate() ! {
	mut tot := 0.0
	for key, p in lp.wallets_pool {
		tot += p.amount
	}
	for key, mut p in lp.wallets_pool {
		if tot > 0 {
			p.poolpercentage = p.amount / tot
		}
	}
}

struct PoolsWalletResult {
pub mut:
	poolusd &Pool
	poolcur &Pool
	wallet  &LPWallet
}

// internal function to return right pools & wallet
// returns
//	poolusd &Pool
// 	poolcur &Pool
// 	wallet &LPWallet
fn (mut dao DAO) pools_wallet_get(account &Account, currency string, ispool bool) !PoolsWalletResult {
	mut lp := dao.pool_get(currency)!
	mut lpusd := dao.pool_get('usdc')!

	lp.calculate()! // calculates how much percent each user has in the liquidity pool
	lpusd.calculate()! // calculates how much percent each user has in the liquidity pool

	mut p := LPWallet{
		account: account
	}
	if ispool {
		if account.address in lp.wallets_pool {
			p = lp.wallets_pool[account.address]
		} else {
			lp.wallets_pool[account.address] = &p
		}
	} else {
		if account.address in lp.wallets_pool {
			p = lp.wallets_private[account.address]
		} else {
			lp.wallets_private[account.address] = &p
		}
	}

	// adjust the modtime
	lpusd.modtime = dao.time_current
	lp.modtime = dao.time_current

	return PoolsWalletResult{
		poolusd: lpusd
		poolcur: lp
		wallet:  &p
	}
}
