module main

import freeflowuniverse.crystallib.data.rpcwebsocket { RpcWsClient }
import freeflowuniverse.crystallib.threefold.web3gw.nostr
import flag
import log
import os
import time

const default_server_address = 'ws://127.0.0.1:8080'

fn execute_rpcs(mut client RpcWsClient, mut logger log.Logger, secret string) ! {
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
	nostr_client.subscribe_text_notes()!

	nostr_client.publish_text_note(tags: [''], content: 'hello world 1!')!
	nostr_client.publish_text_note(tags: [''], content: 'hello world 2!')!

	metadata := nostr.Metadata{
		tags:     ['']
		metadata: nostr.NostrMetadata{
			name:    'test'
			about:   'about test'
			picture: 'test picture'
		}
	}
	nostr_client.publish_metadata(metadata)!

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

	execute_rpcs(mut myclient, mut logger, secret) or {
		logger.error('Failed executing calls: ${err}')
		exit(1)
	}
}
