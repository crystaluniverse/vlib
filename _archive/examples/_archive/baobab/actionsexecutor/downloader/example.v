module main

import freeflowuniverse.crystallib.data.actionsparser
import freeflowuniverse.crystallib.baobab.actionsexecutor
import os
import log

const example_git_root = ''
const example_repo_url = 'https://github.com/threefoldfoundation/www_mycelium.git'
const example_repo_name = 'www_mycelium'
const example_file_url = 'httpsfile://cdnjs.cloudflare.com/ajax/libs/echarts/5.4.3/echarts.min.js'
const example_file_name = 'echarts.min.js'
const example_file_dest = ''

const script_path = '${os.dir(@FILE)}/heroscript.md'

fn main() {
	do() or { panic(err) }
}

fn do() ! {
	actions_script := "
!!downloader.get
    url: '${example_repo_url}'
    name: '${example_repo_name}'
	
    minsize_kb: 1000
    maxsize_kb: 50000

!!downloader.get
    url: '${example_repo_url}'
    name: '${example_repo_name}'
    reset: false
    minsize_kb: 1000
    maxsize_kb: 500000

!!downloader.get
    url: ''
    name: 'echarts.min.js'
    reset: false
    dest: '/tmp/echarts.min.js'
    minsize_kb: 1000
    maxsize_kb: 5000	
"

	mut logger := log.Logger(&log.Log{
		level: $if debug { .debug } $else { .info }
	})
	ap := actionsparser.new(path: script_path)!

	for i, action in ap.actions {
		logger.info('Running action ${action}')
		if i == 0 {
			logger.info('This action should fail because repo size is greater than max kb')
			actionsexecutor.sal_downloader(action) or {
				logger.info('Action failed. Next action will try to download repo with greater maxkb.')
				continue
			}
		}
		actionsexecutor.sal_downloader(action)!
		logger.info('Action executed succesfully.')
	}

	if os.exists('/tmp/download/echarts.min.js') {
	}
}
