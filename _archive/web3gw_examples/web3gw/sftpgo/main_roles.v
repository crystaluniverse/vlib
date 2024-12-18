module main

import freeflowuniverse.crystallib.threefold.web3gw.sftpgo
import flag
import os
import log

const default_server_address = 'http://localhost:8080/api/v2'

fn roles_crud(mut cl sftpgo.SFTPGoClient, mut logger log.Logger) {
	// create role struct
	mut role := sftpgo.Role{
		name:        'role1'
		description: 'role 1 description'
		users:       []
		admins:      []
	}

	// list existing roles
	roles := cl.list_roles() or {
		logger.error('failed to list roles: ${err}')
		exit(1)
	}
	logger.info('roles: ${roles}')

	// add Role
	created_role := cl.add_role(role) or {
		logger.error('failed to add role: ${err}')
		exit(1)
	}
	logger.info('role created: ${created_role}')

	// get role
	returned_role := cl.get_role(role.name) or {
		logger.error('failed to get folder: ${err}')
		exit(1)
	}
	logger.info('role: ${returned_role}')

	// update role
	role.description = 'role1 description modified'
	cl.update_role(role) or {
		logger.error('failed to update role: ${err}')
		exit(1)
	}

	// get updated role
	updated_role := cl.get_role(role.name) or {
		logger.error('failed to get updated role: ${err}')
		exit(1)
	}
	logger.info('updated_role: ${updated_role}')

	// delete role
	deleted := cl.delete_role(role.name) or {
		logger.error('failed to update role: ${err}')
		exit(1)
	}
	logger.info('role deleted: ${deleted}')
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
	roles_crud(mut cl, mut logger)
}
