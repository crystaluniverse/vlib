module main

import freeflowuniverse.crystallib.threefold.web3gw.sftpgo
import flag
import os
import log

const default_server_address = 'http://localhost:8080/api/v2'

fn folders_crud(mut cl sftpgo.SFTPGoClient, mut logger log.Logger) {
	// create folder struct
	mut folder := sftpgo.Folder{
		name:        'folder2'
		mapped_path: '/folder2'
		description: 'folder 2 description'
	}

	// list all folders
	folders := cl.list_folders() or {
		logger.error('failed to list folder: ${err}')
		exit(1)
	}
	logger.info('folders: ${folders}')

	// add folder
	created_folder := cl.add_folder(folder) or {
		logger.error('failed to add folder: ${err}')
		exit(1)
	}
	logger.info('folder created: ${created_folder}')

	// get folder
	returned_folder := cl.get_folder(folder.name) or {
		logger.error('failed to get folder: ${err}')
		exit(1)
	}
	logger.info('folder: ${returned_folder}')

	// update folder
	folder.description = 'folder2 description modified'
	cl.update_folder(folder) or {
		logger.error('failed to update folder: ${err}')
		exit(1)
	}
	// get updated folder
	updated_folder := cl.get_folder(folder.name) or {
		logger.error('failed to get updated folder: ${err}')
		exit(1)
	}
	logger.info('updated folder: ${updated_folder}')

	deleted := cl.delete_folder(folder.name) or {
		logger.error('failed to update user: ${err}')
		exit(1)
	}
	logger.info('folder deleted: ${deleted}')
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
	folders_crud(mut cl, mut logger)
}
