module main

import freeflowuniverse.crystallib.threefold.web3gw.sftpgo
import flag
import os
import log

const default_server_address = 'http://localhost:8080/api/v2'

fn get_events(mut cl sftpgo.SFTPGoClient, mut logger log.Logger) {
	fs_events := cl.get_fs_events(0, 0, 100, 'DESC') or {
		logger.error('failed to list fs events: ${err}')
		exit(1)
	}

	logger.info('fs_events: ${fs_events}')

	provider_events := cl.get_provider_events(0, 0, 100, 'DESC') or {
		logger.error('failed to list provider events: ${err}')
		exit(1)
	}
	logger.info('provider_events: ${provider_events}')
}

fn main() {
	mut fp := flag.new_flag_parser(os.args)
	fp.application('Welcome to the SFTPGO sal.')
	fp.limit_free_args(0, 0)!
	fp.description('')
	fp.skip_executable()
	address := fp.string('address', `a`, '${default_server_address}', 'address of sftpgo server. default ${default_server_address}')
	key := fp.string('apikey', `k`, '', 'the API key generated from the sftpgo server')
	debug_log := fp.bool('debug', 0, false, 'By setting this flag the client will print debug logs too.')
	_ := fp.finalize() or {
		eprintln(err)
		println(fp.usage())
		exit(1)
	}

	args := sftpgo.SFTPGOClientArgs{
		address: address
		key:     key
	}
	mut cl := sftpgo.new(args) or {
		println(err)
		exit(1)
	}
	mut logger := log.Logger(&log.Log{
		level: if debug_log { .debug } else { .info }
	})
	get_events(mut cl, mut logger)
}
