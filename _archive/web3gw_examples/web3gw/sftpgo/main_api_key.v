module main

import freeflowuniverse.crystallib.threefold.web3gw.sftpgo
import flag
import os

const default_server_address = 'http://localhost:8080/api/v2'

fn main() {
	mut fp := flag.new_flag_parser(os.args)
	fp.application('Welcome to the SFTPGO sal.')
	fp.limit_free_args(0, 0)!
	fp.description('')
	fp.skip_executable()
	address := fp.string('address', `a`, '${default_server_address}', 'address of sftpgo server. default ${default_server_address}')
	jwt := fp.string('jwt', `j`, '', 'the jwt from the sftpgo server, generate one from http://localhost:8080/api/v2/token')
	name := fp.string('name', `n`, 'key name', 'the key name')
	scope := fp.int('scope', `s`, 1, 'key scope')
	description := fp.string('description', `c`, 'key description', 'the key description')
	user := fp.string('user', `u`, '', 'either pass it or pass an admin ')
	admin := fp.string('admin', `d`, '', 'the admin username either pass it or pass a user ')

	args := sftpgo.APIKeyParams{
		address:     address
		jwt:         jwt
		name:        name
		scope:       scope
		description: description
		user:        user
		admin:       admin
	}
	mut api_key := sftpgo.generate_api_key(args) or {
		println(err)
		exit(1)
	}
	println(api_key)
}
