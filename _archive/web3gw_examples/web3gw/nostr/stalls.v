module main

import freeflowuniverse.crystallib.data.rpcwebsocket { RpcWsClient }
import freeflowuniverse.crystallib.threefold.web3gw.nostr
import flag
import log
import os
import time

const default_server_address = 'ws://127.0.0.1:8080'

fn create_stall_and_product(mut client RpcWsClient, mut logger log.Logger, secret string) ! {
	mut nostr_client := nostr.new(mut client)

	key := if secret == '' {
		k := nostr_client.generate_keypair()!
		logger.info('Key: ${k}')
		k
	} else {
		secret
	}

	nostr_client.load(key)!

	nostr_id := nostr_client.get_id()!
	logger.info('Nostr: ID: ${nostr_id}')

	nostr_client.connect_to_relay('https://nostr01.grid.tf/')!

	nostr_client.subscribe_to_stall_creation()!
	nostr_client.subscribe_to_product_creation()!

	stall := nostr.Stall{
		id:          'stall1'
		name:        'stall1'
		description: 'stall1'
		currency:    'TFT'
		shipping:    [
			nostr.Shipping{
				id:        'shipping1'
				name:      'shipping1'
				cost:      10000.00
				countries: ['']
			},
		]
	}

	input := nostr.StallCreateInput{
		tags:  ['']
		stall: stall
	}

	nostr_client.publish_stall(input)!

	product := nostr.Product{
		id:          'product1'
		stall_id:    'stall1'
		name:        'product1'
		description: 'product1'
		images:      ['']
		currency:    'TFT'
		price:       10000.00
		quantity:    1
		specs:       [][]string{}
	}

	product_input := nostr.ProductCreateInput{
		tags:    ['']
		product: product
	}

	nostr_client.publish_product(product_input)!

	logger.info('published stall and product')

	time.sleep(5 * time.second)

	events := nostr_client.get_events()!
	logger.info('Events: ${events}')

	// Close subscriptions
	subscription_ids := nostr_client.get_subscription_ids()!
	logger.info('Subscription IDs: ${subscription_ids}')
	for id in subscription_ids {
		nostr_client.close_subscription(id)!
	}
}

fn main() {
	mut fp := flag.new_flag_parser(os.args)
	fp.application('Welcome to the web3_proxy client. The web3_proxy client allows you to execute all remote procedure calls that the web3_proxy server can handle.')
	fp.limit_free_args(0, 0)!
	fp.description('')
	fp.skip_executable()
	secret := fp.string('secret', `s`, '', 'The secret to use for nostr.')
	address := fp.string('address', `a`, '${default_server_address}', 'The address of the web3_proxy server to connect to.')
	debug_log := fp.bool('debug', 0, false, 'By setting this flag the client will print debug logs too.')
	_ := fp.finalize() or {
		eprintln(err)
		println(fp.usage())
		exit(1)
	}

	mut logger := log.Logger(&log.Log{
		level: if debug_log { .debug } else { .info }
	})

	mut myclient := rpcwebsocket.new_rpcwsclient(address, &logger) or {
		logger.error('Failed creating rpc websocket client: ${err}')
		exit(1)
	}

	_ := spawn myclient.run()

	create_stall_and_product(mut myclient, mut logger, secret) or {
		logger.error('Failed executing calls: ${err}')
		exit(1)
	}
}
