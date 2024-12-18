module currency

import freeflowuniverse.crystallib.ui.console

// pub fn test_amount_get() {
// 	// assert amount_get("U s d 900").val == 900
// 	// assert amount_get("U s d 900").currency.name == 'USD'
// 	console.print_debug(amount_get('U s d 900'))
// 	console.print_debug(amount_get('euro321'))
// 	panic("SSD"
// 	)
// }

pub fn test_rates_get() {
	lock currencies {
		refresh()!

		println(currencies)

		currencies['TFT'] = Currency{
			name:   'TFT'
			usdval: 0.01
		}
		currencies['AED'] = Currency{
			name:   'AED'
			usdval: 0.25
		}

		currencies['USD'] = Currency{
			name:   'USD'
			usdval: 1.0
		}

		mut u := amount_get('1$')!
		u2 := u.exchange(get('tft')!)!
		assert u2.val == 100.0

		mut a := amount_get('10Aed')!
		mut b := amount_get('AED 10')!
		assert a.val == b.val
		assert a.currency == b.currency
		assert a.val == 10.0

		c := a.exchange(get('tft ')!)!
		assert c.val == 250.0

		mut aa2 := amount_get('0')!
		assert aa2.val == 0.0

		mut aa := amount_get('10')!
		assert aa.val == 10.0
		assert aa.currency.name == 'USD'
		assert aa.currency.usdval == 1.0

		mut a3 := amount_get('20 tft')!
		println(a3)
		assert a3.currency.usdval == 0.01
		assert a3.usd() == 20.0 * 0.01

		mut a4 := amount_get('20 k tft')!
		println(a4)
		assert a4.currency.usdval == 0.01
		assert a4.usd() == 20 * 1000.0 * 0.01

		mut a5 := amount_get('20mtft')!
		assert a5.usd() == 20 * 1000000.0 * 0.01
	}
}
