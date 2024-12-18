module currency

pub struct Amount {
pub mut:
	currency Currency
	val      f64
}

// convert an Amount into usd
// ARGS:
// - Amount
pub fn (a Amount) usd() f64 {
	// calculate usd value towards f64
	usd_val := a.val * a.currency.usdval
	return f64(usd_val)
}

// amount_get
// gets amount and currency from a string input
// ARGS:
// - amount_str string : a human-written string
// -decimals are done with US notation (.)
// - check in string for format  e.g. 10.3usd or '10 usd' or '10 USD' or '10 usDC'
// allows £,$,€ to be used as special cases
pub fn amount_get(amount_ string) !Amount {
	check()
	mut amount := amount_.to_upper()
	numbers := ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.']
	for i in ['_', ',', ' '] {
		amount = amount.replace(i, '')
	}

	amount = amount.replace('$', 'USD')
	amount = amount.replace('£', 'GBP')
	amount = amount.replace('€', 'EUR')

	// checks if amount or code given first
	mut num_first := false
	item := amount[0..1]
	if item in numbers {
		num_first = true
	}

	// split up string into two parts, code and amount
	mut code := ''
	mut num := ''
	mut split_string := amount.split('')
	if num_first {
		mut count := 0
		for index in split_string {
			if index !in numbers {
				num = amount[0..count]
				code = amount[count..amount.len]
				break
			}
			count += 1
		}
	} else {
		mut count := 0
		for index in split_string {
			if index in numbers {
				code = amount[0..count]
				num = amount[count..amount.len]
				break
			}
			count += 1
		}
	}
	// remove spaces from code and capitalise
	code = code.to_upper().trim_space()
	code2 := code.replace('.', '').replace('0', '').trim_space()
	if code2 == '' {
		code = ''
	}
	if code == '%' {
		amount = '${amount.f64() / 100}'
		code = ''
	}
	if code == '' {
		num = amount
		code = 'USD'
		// } else {
		// 	rlock currencies {
		// 		if code !in currencies {
		// 			rates_get([code], false)! // not sure this will work
		// 			rates_get([code], true)!
		// 		}
		// 	}
	}

	mut num2 := num.f64()

	if code.starts_with('E+') {
		return error('found currency code with E+ notation, is overflow: ${amount_}')
	}
	if code.len == 1 {
		if code.starts_with('K') {
			code = 'USD'
			num2 = num2 * 1000
		} else if code.starts_with('M') {
			code = 'USD'
			num2 = num2 * 1000000
		} else {
			return error('found currency code with 1 letter but did not start with k or m (killo or million): ${code}')
		}
	} else if code.len == 4 {
		if code.starts_with('K') {
			code = code[1..4]
			num2 = num2 * 1000
		} else if code.starts_with('M') {
			code = code[1..4]
			num2 = num2 * 1000000
		} else {
			return error('found currency code with 4 letters but did not start with k or m (killo or million): ${code}')
		}
	}

	mut mycurr := get(code)!

	mut amount2 := Amount{
		val:      num2
		currency: mycurr
	}

	return amount2
}

// pub fn (mut a0 Amount) add (a2 Amount)! {
// 	target_currency := amounts[0].currency

// 	mut total_val := f64(0)
// 	for amount in amounts {
// 		if amount.currency != target_currency {
// 			return error("Input amounts are of different currencies")
// 		}
// 		total_val += amount.val
// 	}
// 	return Amount{
// 		currency: target_currency
// 		val: total_val
// 	}
// }
