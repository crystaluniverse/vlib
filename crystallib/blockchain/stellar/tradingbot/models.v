module tradingbot

import freeflowuniverse.crystallib.blockchain.stellar

pub enum StellarTradingBotOperation {
	sell
	buy
}

pub struct StellarTradingBot {
mut:
	hclient stellar.HorizonClient // Horizon client
	sclient stellar.StellarClient // Stellar client
pub mut:
	account_secret  string // private key
	account_address string // public key

	selling_asset_code   string // asset to sell
	selling_asset_issuer string // issuer of the asset to sell
	selling_asset_type   string // type of the asset to sell
	buying_asset_code    string // asset to buy
	buying_asset_issuer  string // issuer of the asset to buy
	buying_asset_type    string // type of the asset to buy
	// selling stellar.OfferAssetType
	// buying  stellar.OfferAssetType

	buying_target_price  f64 // price to buy at
	selling_target_price f64 // price to sell at
	selling_amount       f64
	buying_amount        f64
	preserve             f64 // min balance to have in account
}
