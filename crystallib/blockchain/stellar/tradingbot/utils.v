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
fn determine_asset_type(asset_code string) string {
	return if asset_code.len <= 4 {
		'credit_alphanum4'
	} else {
		'credit_alphanum12'
	}
}

// fn get_offer_asset_type(asset_type string, asset_code string, asset_issuer string) stellar.OfferAssetType {
// 	if asset_type == 'native' {
// 		return stellar.OfferAssetType('native')
// 	}

// 	mut asset := stellar.AssetType{}
// 	if asset_code.len <= 4 {
// 		asset.credit_alphanum4 = stellar.Asset{
// 			asset_code: asset_code
// 			issuer: asset_issuer
// 		}
// 	} else {
// 		asset.credit_alphanum12 = stellar.Asset{
// 			asset_code: asset_code
// 			issuer: asset_issuer
// 		}
// 	}

// 	return stellar.OfferAssetType(asset_type)
// }
