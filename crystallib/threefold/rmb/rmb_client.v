module rmb

// import freeflowuniverse.crystallib.clients.httpconnection
import freeflowuniverse.crystallib.clients.redisclient { RedisURL }
import os

pub struct RMBClient {
pub mut:
	relay_url        string
	tfchain_url      string
	tfchain_mnemonic string
	redis            &redisclient.Redis @[str: skip]
}

pub enum TFNetType {
	unspecified
	main
	test
	dev
	qa
}

@[params]
pub struct RMBClientArgs {
pub:
	nettype     TFNetType
	relay_url   string
	tfchain_url string
}

//  params
// 		relay_url string
// 		TFNetType, default not specified, can chose 	unspecified, main, test, dev, qa
// 		tfchain_url string= e.g. "wss://relay.dev.grid.tf:443"    		OPTIONAL
// 		tfchain_mnemonic string= e.g. "wss://tfchain.dev.grid.tf:443"  	OPTIONAL
pub fn new(args_ RMBClientArgs) !RMBClient {
	mut args := args_
	if tfchain_mnemonic == '' {
		if 'TFCHAINSECRET' in os.environ {
			args.tfchain_mnemonic = os.environ['TFCHAINSECRET']
		} else {
			return error('need to specify TFCHAINSECRET (menomics for TFChain) as env argument or inside client')
		}
	}
	if args.nettype == .main {
		args.relay_url = 'wss://relay.grid.tf:443'
		args.tfchain_url = 'wss://tfchain.grid.tf:443'
	}
	if args.nettype == .test {
		args.relay_url = 'wss://relay.test.grid.tf:443'
		args.tfchain_url = 'wss://tfchain.test.grid.tf:443'
	}
	if args.nettype == .dev {
		args.relay_url = 'wss://relay.dev.grid.tf:443'
		args.tfchain_url = 'wss://tfchain.dev.grid.tf:443'
	}
	if args.nettype == .qa {
		args.relay_url = 'wss://relay.qa.grid.tf:443'
		args.tfchain_url = 'wss://tfchain.qa.grid.tf:443'
	}

	mut redis := redisclient.core_get(RedisURL{})!

	mut cl := RMBClient{
		redis:            redis
		relay_url:        args.relay_url
		tfchain_url:      args.tfchain_url
		tfchain_mnemonic: args.tfchain_mnemonic
	}
	if args.relay_url == '' || args.tfchain_url == '' {
		return error('need to specify relay_url and tfchain_url.')
	}
	if args.tfchain_mnemonic.len < 20 {
		return error('need to specify tfchain mnemonic, now too short.')
	}

	// TODO: there should be a check here that rmb peer is accessible and working

	return cl
}
