module currency

import json
import freeflowuniverse.crystallib.clients.httpconnection

struct ResponseBody {
	motd    string
	success string
	base    string
	date    string
	rates   map[string]f32
}

// // gets the latest currency exchange rates from an API
// // ARGS:
// // - an array of fiat codes e.g ['EUR', 'AED']
// // - an array of crypto codes e.g ['TERRA']
// pub fn get_rates(fiat_array []string, crypto_array []string) !(map[string]f32, map[string]f32) {
// 	mut fiat_codes := fiat_array.str()
// 	for i in ["'", '[', ']', ' '] {
// 		fiat_codes = fiat_codes.replace(i, '')
// 	}

// 	mut crypto_codes := crypto_array.str()
// 	for i in ["'", '[', ']', ' '] {
// 		crypto_codes = crypto_codes.replace(i, '')
// 	}

// 	mut response := http.get('https://api.exchangerate.host/latest?base=USD&symbols=USDT,TFT&source=crypto --header 'apikey: '') or {return error("Failed to get crypto http response: $err")}

// 	response = http.get('https://api.exchangerate.host/latest?base=USD&symbols=$fiat_codes') or {return error("Failed to get fiat http response: $err")}
// 	fiat_decoded := json.decode(ResponseBody, response.body) or {return error("Failed to decode fiat json: $err")}

// 	return fiat_decoded.rates, crypto_decoded.rates
// }

// // gets the latest currency exchange rates from an API on internet
// - an array of fiat codes e.g ['EUR', 'AED']
// - an array of crypto codes e.g ['TERRA']
// e.g.
pub fn rates_get(cur_array []string, crypto bool) ! {
	panic('not implemented,api changed')
	// http.CommonHeader.authorization: 'Bearer $h.auth.auth_token'
	mut conn := httpconnection.new(
		name:  'example'
		url:   'https://api.apilayer.com/exchangerates_data/'
		cache: true
	)!
	// do the cache on the connection
	conn.cache.expire_after = 3600 * 24 * 2 // make the cache expire_after 2 days
	mut cur_codes := cur_array.str()
	for i in ["'", '[', ']', ' '] {
		cur_codes = cur_codes.replace(i, '')
	}
	mut prefix := 'latest?base=USD&symbols=${cur_codes}'
	if crypto {
		prefix += '&source=crypto'
	}
	// TODO: conn.get hits invalid memory access, let's fix the issue
	response := conn.get(prefix: prefix)!
	decoded := json.decode(ResponseBody, response) or {
		return error('Failed to decode crypto json: ${err}')
	}
	println(decoded.rates)
	for key, rate in decoded.rates {
		c := Currency{
			name:   key.to_upper()
			usdval: 1 / rate
		}
		lock {
			currencies[key.to_upper()] = c
		}
	}
}
