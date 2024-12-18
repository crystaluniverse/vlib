module dao

// check if the asset is actually healthy
fn asset_check(a &Pool) ! {
	if a.currency == 'usdc' {
		if a.usdprice_buy != 1 {
			return error('usd can only be price of 1, its the base currency')
		}
		if a.usdprice_sell != 1 {
			return error('usd can only be price of 1, its the base currency')
		}
		return
	}

	if a.currency == 'tft' {
		if a.usdprice_buy < 0.04 || a.usdprice_buy > 0.2 {
			return error('tft between 0.04 and 0.2')
		}
		if a.usdprice_sell < 0.04 || a.usdprice_sell > 0.2 {
			return error('tft between 0.04 and 0.2')
		}
	}
}
