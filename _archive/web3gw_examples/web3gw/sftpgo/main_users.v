module main

import freeflowuniverse.crystallib.threefold.web3gw.sftpgo
import flag
import os
import log

const default_server_address = 'http://localhost:8080/api/v2'

fn users_crud(mut cl sftpgo.SFTPGoClient, mut logger log.Logger) {
	mut user := sftpgo.User{
		username:    'test_user'
		email:       'test_email@test.com'
		password:    'test_password'
		public_keys: [
			'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDTwULSsUubOq3VPWL6cdrDvexDmjfznGydFPyaNcn7gAL9lRxwFbCDPMj7MbhNSpxxHV2+/iJPQOTVJu4oc1N7bPP3gBCnF51rPrhTpGCt5pBbTzeyNweanhedkKDsCO2mIEh/92Od5Hg512dX4j7Zw6ipRWYSaepapfyoRnNSriW/s3DH/uewezVtL5EuypMdfNngV/u2KZYWoeiwhrY/yEUykQVUwDysW/xUJNP5o+KSTAvNSJatr3FbuCFuCjBSvageOLHePTeUwu6qjqe+Xs4piF1ByO/6cOJ8bt5Vcx0bAtI8/MPApplUU/JWevsPNApvnA/ntffI+u8DCwgP',
		]
		permissions: {
			'/': ['*']
		}
		status:      1
	}

	// add user
	created_user := cl.add_user(user) or {
		logger.error('Failed to add user: ${err}')
		exit(1)
	}
	logger.info('user created: ${created_user}')

	returned_user := cl.get_user('test_user') or {
		logger.error('failed to get user: ${err}')
		exit(1)
	}
	logger.info('got user: ${returned_user}')

	// update user
	user.email = 'test_email@modified.com'
	cl.update_user(user) or {
		logger.error('failed to update user: ${err}')
		exit(1)
	}

	updated_user := cl.get_user('test_user') or {
		logger.error('failed to get updated user: ${err}')
		exit(1)
	}
	logger.info('updated user: ${updated_user}')

	deleted := cl.delete_user('test_user') or {
		logger.error('failed to update user: ${err}')
		exit(1)
	}
	logger.info('user deleted: ${deleted}')
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
	users_crud(mut cl, mut logger)
}
