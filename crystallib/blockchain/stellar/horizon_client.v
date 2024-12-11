module stellar

import freeflowuniverse.crystallib.clients.httpconnection
import json
import x.json2

pub struct HorizonClient {
pub mut:
	url string
}

// Struct for the order book request
pub struct OrderBookRequest {
pub mut:
	selling_asset_type   string @[json: 'sellingAssetType']
	selling_asset_code   string @[json: 'sellingAssetCode']
	selling_asset_issuer string @[json: 'sellingAssetIssuer']
	buying_asset_type    string @[json: 'buyingAssetType']
	buying_asset_code    string @[json: 'buyingAssetCode']
	buying_asset_issuer  string @[json: 'buyingAssetIssuer']
	limit                int
}

// Struct for the order book response (you'll need to match Horizon API's response format)
pub struct OrderBook {
	// Add fields based on the Horizon API order book response
pub:
	bids []Order
	asks []Order
}

pub struct Order {
pub:
	price_r Price // Price ratio as returned by Stellar Horizon
	price   string
	amount  string
}

// TODO: this needs to be configured to work on both networks
pub fn new_horizon_client(network StellarNetwork) !HorizonClient {
	url := match network {
		.mainnet {
			'https://horizon.stellar.org'
		}
		.testnet {
			'https://horizon-testnet.stellar.org/'
		}
	}

	mut cl := HorizonClient{
		url: url
	}
	return cl
}

pub fn (self HorizonClient) get_account(pubkey string) !StellarAccount {
	mut client := httpconnection.new(name: 'horizon', url: self.url)!

	result := client.get_json(
		prefix: 'accounts/${pubkey}'
		debug: true
		cache_disable: false
	)!

	mut a := json.decode(StellarAccount, result) or {
		return error('Failed to create StellarAccount: error: ${result}')
	}

	return a
}

pub fn (self HorizonClient) get_last_transaction(address string) !TransactionInfo {
	mut client := httpconnection.new(name: 'horizon', url: self.url)!

	result := client.get_json(
		prefix: 'accounts/${address}/transactions?limit=1&order=desc'
		debug: true
		cache_disable: false
	)!

	tx := json.decode(TransactionInfo, result) or {
		return error('Failed to decode TransactionInfo: error: ${result}')
	}

	return tx
}

// Function to get the order book
pub fn (self HorizonClient) get_order_book(order_book_request OrderBookRequest) !OrderBook {
	// Construct the query parameters
	mut query_params := map[string]json2.Any{}
	mut client := httpconnection.new(name: 'horizon', url: self.url)!

	$for field in order_book_request.fields {
		query_params[field.name] = order_book_request.$(field.name)
	}
	result := client.get_json(
		prefix: 'order_book?' + url_encode(query_params)
		debug: true
		cache_disable: false
	)!

	order_book := json.decode(OrderBook, result) or {
		return error('Failed to decode OrderBook: error: ${result}')
	}

	return order_book
}

@[params]
pub struct GetOfferArgs {
pub mut:
	seller string
	limit  int = 100
}

struct OffersResponse {
	links    RootLinks      @[json: '_links']
	embedded OffersEmbedded @[json: '_embedded']
}

struct OffersEmbedded {
	records []OfferModel
}

pub struct OfferModel {
pub mut:
	id                   string
	paging_token         string
	seller               string
	amount               string
	price                string
	last_modified_ledger int
	last_modified_time   string
	selling              GetOfferAssetInfo
	buying               GetOfferAssetInfo
}

pub struct GetOfferAssetInfo {
pub mut:
	asset_type   string
	asset_code   string
	asset_issuer string
}

// Function to list offers
pub fn (self HorizonClient) get_offers(args GetOfferArgs) ![]OfferModel {
	mut client := httpconnection.new(name: 'horizon', url: self.url)!
	mut query_params := map[string]json2.Any{}
	$for field in args.fields {
		query_params[field.name] = args.$(field.name)
	}
	result := client.get_json(
		prefix: 'offers?' + url_encode(query_params)
		debug: true
		cache_disable: false
	)!

	response := json.decode(OffersResponse, result) or {
		return error('Failed to decode OrderBook: error: ${result}')
	}

	return response.embedded.records
}
