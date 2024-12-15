module tradingbot

import math
import freeflowuniverse.crystallib.ui.console

// Determines the Stellar asset type based on code length
fn determine_asset_type(asset_code string) string {
	return if asset_code.len <= 4 {
		'credit_alphanum4'
	} else {
		'credit_alphanum12'
	}
}

// Rounding function, to the specified precision
fn round_to_precision(num f64, precision int) f64 {
	factor := math.pow(10, precision)
	return math.round(num * factor) / factor
}

fn log(message string, sell bool) {
	if sell {
		console.cprintln(foreground: .light_green, text: '|Sell logs| ${message}')
	} else {
		console.cprintln(foreground: .light_blue, text: '|Buy logs| ${message}')
	}
}
