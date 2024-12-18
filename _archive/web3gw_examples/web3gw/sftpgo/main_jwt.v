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
	username := fp.string('username', `u`, '', 'username of the user you want to generate jwt for')
	password := fp.string('password', `p`, '', 'user password')

	args := sftpgo.JWTArgs{
		address:  address
		username: username
		password: password
	}
	mut api_key := sftpgo.generate_jwt_token(args) or {
		println(err)
		exit(1)
	}
	println(api_key)
}
