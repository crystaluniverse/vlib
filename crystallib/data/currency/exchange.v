module currency

// exchagen the amount to requested target currency
pub fn (mut a0 Amount) exchange(target_currency_ Currency) !Amount {
	mut target_currency := target_currency_
	if a0.currency != target_currency {
		mut a3 := Amount{
			currency: &target_currency
			val:      a0.val * a0.currency.usdval / target_currency.usdval
		}
		return a3
	}
	return a0
}
