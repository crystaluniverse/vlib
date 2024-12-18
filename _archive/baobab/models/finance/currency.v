module finance

import net.http
import json

//? why is this a new struct, cant we just use a map instead?
pub struct Currencies {
pub mut:
	currencies map[string]Currency
}

pub struct Currency {
pub mut:
	name   string
	usdval f64
}

pub struct Amount {
pub mut:
	currency Currency
	val      f64
}

// convert an Amount into usd
// ARGS:
// - Amount
// TODO: hard code in exchange rates, later this struct can be filled in with an API or something
pub fn (a Amount) usd() f64 {
	// calculate usd value towards f64
	usd_val := a.val * a.currency.usdval
	return f64(usd_val)
}

// amount_get
// gets amount and currency from a string input
// ARGS:
// - amount_str string : a human-written string
// check in string for format  e.g. 10usd or '10 usd' or '10 USD' or '10 usDC'
//? Is USDC, the only exception that needs to be considered
//? otherwise it is very difficult to manage ie do we group in USDT as well?
//? and then for other currencies and their digital variants
// allows £,$,€ to be used as special cases
pub fn amount_get(amount_ string) &Amount {
	mut amount := amount_
	numbers := ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']
	for i in ['_', ',', '.', ' '] {
		amount = amount.replace(i, '')
	}

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

	code_nice := match code {
		'$' { 'USD' }
		'£' { 'GBP' }
		'€' { 'EUR' }
		else { code.to_upper() }
	}

	currencies := get_currencies() // TODO with api

	amount2 := Amount{
		val:      f64(num.int())
		currency: currencies.currencies[code_nice] //?How to handle an error here
	}

	return &amount2
}

pub fn add_amounts(amounts []&Amount) !Amount {
	target_currency := amounts[0].currency

	mut total_val := f64(0)
	for amount in amounts {
		if amount.currency != target_currency {
			return error('Input amounts are of different currencies')
		}
		total_val += amount.val
	}
	return Amount{
		currency: target_currency
		val:      total_val
	}
}

struct ResponseBody {
	motd    string
	success string
	base    string
	date    string
	rates   map[string]f32
}

// gets the latest currency exchange rates from an API
// ARGS:
// - an array of fiat codes e.g ['EUR', 'AED']
// - an array of crypto codes e.g ['TERRA']
pub fn get_rates(fiat_array []string, crypto_array []string) !(map[string]f32, map[string]f32) {
	mut fiat_codes := fiat_array.str()
	for i in ["'", '[', ']', ' '] {
		fiat_codes = fiat_codes.replace(i, '')
	}

	mut crypto_codes := crypto_array.str()
	for i in ["'", '[', ']', ' '] {
		crypto_codes = crypto_codes.replace(i, '')
	}

	mut response := http.get('https://api.exchangerate.host/latest?base=USD&symbols=${crypto_codes}&source=crypto') or {
		return error('Failed to get crypto http response: ${err}')
	}
	crypto_decoded := json.decode(ResponseBody, response.body) or {
		return error('Failed to decode crypto json: ${err}')
	}

	response = http.get('https://api.exchangerate.host/latest?base=USD&symbols=${fiat_codes}') or {
		return error('Failed to get fiat http response: ${err}')
	}
	fiat_decoded := json.decode(ResponseBody, response.body) or {
		return error('Failed to decode fiat json: ${err}')
	}

	return fiat_decoded.rates, crypto_decoded.rates
}

// Gets the latest currency exchange rates from a hardcoded list
// ARGS:s
pub fn get_currencies() Currencies {
	mut usd := Currency{
		name:   'USD'
		usdval: 1
	}

	mut eur := Currency{
		name:   'EUR'
		usdval: 0.984
	}

	mut gbp := Currency{
		name:   'GBP'
		usdval: 1.1199
	}

	mut tft := Currency{
		name:   'TFT'
		usdval: 0.0292
	}

	mut egp := Currency{
		name:   'EGP'
		usdval: 0.0509
	}

	mut aed := Currency{
		name:   'AED'
		usdval: 0.2723
	}

	mut usdc := Currency{
		name:   'USDC'
		usdval: 1.0000
	}

	mut currencies := Currencies{
		currencies: {
			'EUR':  &eur
			'GBP':  &gbp
			'USD':  &usd
			'TFT':  &tft
			'AED':  &aed
			'USDC': &usdc
			'EGP':  &egp
		}
	}

	return currencies
}
