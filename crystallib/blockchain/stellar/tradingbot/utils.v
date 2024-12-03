module tradingbot

import freeflowuniverse.crystallib.blockchain.stellar

// Normalizes asset codes and validates issuers
fn normalize_assets(args StellarTradingBotArgs) !StellarTradingBotArgs {
	mut args_ := args
	if args_.selling_asset_code != 'XLM' && args_.selling_asset_issuer.len == 0 {
		return error('Invalid selling asset issuer. Asset code is ${args_.selling_asset_code}')
	}
	if args_.buying_asset_code != 'XLM' && args_.buying_asset_issuer.len == 0 {
		return error('Invalid buying asset issuer. Asset code is ${args_.buying_asset_code}')
	}
	return args_
}

// Determines the Stellar asset type based on code length
fn determine_asset_type(asset_code string, asset_issuer string) string {
	return if asset_code == 'XLM' && asset_issuer.len == 0 {
		'native'
	} else if asset_code.len <= 4 {
		'credit_alphanum4'
	} else {
		'credit_alphanum12'
	}
}

// Adds a trust line for a specific asset
fn add_trust_line(mut sclient stellar.StellarClient, asset_code string, issuer string) ! {
	println('Adding trustline for ${asset_code}, Issuer: ${issuer}')
	sclient.add_trust_line(
		asset_code: asset_code
		issuer:     issuer
	)!
}
