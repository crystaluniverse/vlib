module zdb

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.clients.httpconnection
import freeflowuniverse.crystallib.crypt.secrets
import freeflowuniverse.crystallib.sysadmin.startupmanager
import freeflowuniverse.crystallib.clients.zdb
import os
import time

@[params]
pub struct InstallArgs {
pub mut:
	reset        bool
	secret       string
	start        bool = true
	restart      bool
	sequential   bool // if sequential then we autoincrement the keys
	datadir      string = '${os.home_dir()}/var/zdb/data'
	indexdir     string = '${os.home_dir()}/var/zdb/index'
	rotateperiod int    = 1200 // 20 min
}

pub fn install(args_ InstallArgs) ! {
	mut args := args_
	version := '2.0.7'

	res := os.execute('${osal.profile_path_source_and()} zdb --version')
	if res.exit_code == 0 {
		r := res.output.split_into_lines().filter(it.trim_space().len > 0)
		if r.len != 3 {
			return error("couldn't parse zdb version.\n${res.output}")
		}
		myversion := r[1].all_after_first('server, v').all_before_last('(').trim_space()
		if texttools.version(version) > texttools.version(myversion) {
			args.reset = true
		}
	} else {
		args.reset = true
	}

	if args.reset {
		console.print_header('install zdb')

		mut url := ''
		if osal.is_linux_intel() {
			url = 'https://github.com/threefoldtech/0-db/releases/download/v${version}/zdb-${version}-linux-amd64-static'
		} else {
			return error('unsported platform, only linux 64 for zdb for now')
		}

		mut dest := osal.download(
			url:        url
			minsize_kb: 1000
		)!

		osal.cmd_add(
			cmdname: 'zdb'
			source:  dest.path
		)!
	}

	if args.restart {
		restart(args)!
		return
	}

	if args.start {
		start(args)!
	}
}

pub fn restart(args_ InstallArgs) ! {
	stop(args_)!
	start(args_)!
}

pub fn stop(args_ InstallArgs) ! {
	console.print_header('zdb stop')
	mut sm := startupmanager.get()!
	sm.stop('zdb')!
}

pub fn start(args_ InstallArgs) ! {
	mut args := args_

	console.print_header('zdb start')

	mut box := secrets.get()!
	secret := box.secret(key: 'ZDB.SECRET', default: args.secret)!

	mut sm := startupmanager.get()!

	mut cmd := 'zdb --socket ${os.home_dir()}/hero/var/zdb.sock --port 3355 --admin ${secret} --data ${args.datadir} --index ${args.indexdir} --dualnet --protect --rotate ${args.rotateperiod}'
	if args.sequential {
		cmd += ' --mode seq'
	}

	pathlib.get_dir(path: '${os.home_dir()}/hero/var', create: true)!

	sm.start(
		name: 'zdb'
		cmd:  cmd
	)!

	console.print_debug(cmd)

	for _ in 0 .. 50 {
		if check()! {
			return
		}
		time.sleep(10 * time.millisecond)
	}
	return error('zdb not installed properly, check failed.')
}

pub fn check() !bool {
	cmd := 'redis-cli -s /root/hero/var/zdb.sock PING'

	result := os.execute(cmd)
	if result.exit_code > 0 {
		return error('${cmd} failed with exit code: ${result.exit_code} and error: ${result.output}')
	}

	if result.output.trim_space() == 'PONG' {
		console.print_debug('zdb is answering.')
		// return true
	}

	// TODO: need to work on socket version
	// mut db := zdb.get('${os.home_dir()}/hero/var/zdb.sock', secret()!, 'test')!
	mut db := client()!

	// check info returns info about zdb
	info := db.info()!
	// console.print_debug(info)

	assert info.contains('server_name: 0-db')

	console.print_debug('zdb is answering.')
	return true
}

pub fn secret() !string {
	mut box := secrets.get()!
	secret := box.get('ZDB.SECRET')!
	return secret
}

pub fn client() !zdb.ZDB {
	mut db := zdb.get('localhost:3355', secret()!, 'test')!
	return db
}
