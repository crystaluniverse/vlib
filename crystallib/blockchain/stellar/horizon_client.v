module stellar

import freeflowuniverse.crystallib.clients.httpconnection
import json

pub struct HorizonClient {
pub mut:
	url string
}

// TODO: this needs to be configured to work on both networks
pub fn new_horizon_client(network string) !HorizonClient {
	url := match network {
		'mainnet' {
			'https://horizon.stellar.org'
		}
		'testnet' {
			'https://horizon-testnet.stellar.org/'
		}
		else {
			return error('network must be mainnet or testnet')
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

	// println(a)

	return a
}
