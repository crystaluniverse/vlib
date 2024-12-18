module juggler

import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.core.playcmds
import freeflowuniverse.crystallib.core.playbook
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.servers.caddy
import freeflowuniverse.crystallib.clients.httpconnection
import veb
import os
import json
import time

const instance_name = 'testinstance'

pub fn test_juggler_run() ! {
	mut j := get(name: '${instance_name}0')!
	spawn j.run(8085)
}

pub fn test_juggler_index() {
	mut j := get(name: '${instance_name}1')!
	j.index(mut Context{})
}

pub fn test_juggler_get_repo_playbook() ! {
	coderoot := if 'CODEROOT' in os.environ() && os.environ()['CODEROOT'] != '' {
		os.environ()['CODEROOT']
	} else {
		'${os.home_dir()}/code'
	}

	mut j := get(
		name:        '${instance_name}3'
		config_path: '${coderoot}/github/freeflowuniverse/crystallib/crystallib/develop/juggler/testdata'
	)!

	// should return none since no cicd playbook exists for repo
	if _ := j.get_repo_playbook(RepoArgs{
		host:      'github'
		full_name: 'freeflowuniverse/webcomponents'
	})
	{
		assert false
	} else {
		assert true
	}

	// should return playbook in testdata since mock event is from crystallib
	if mut pb := j.get_repo_playbook(RepoArgs{
		full_name: 'freeflowuniverse/crystallib'
		host:      'github'
	})
	{
		assert true
	} else {
		assert false
	}
}

pub fn test_juggler_trigger() {
	mut j := get(name: '${instance_name}2')!
	j.trigger(mut Context{})

	coderoot := if 'CODEROOT' in os.environ() && os.environ()['CODEROOT'] != '' {
		os.environ()['CODEROOT']
	} else {
		'${os.home_dir()}/code'
	}

	j = get(
		name:        '${instance_name}4'
		config_path: '${coderoot}/github/freeflowuniverse/crystallib/crystallib/develop/juggler/testdata'
	)!

	spawn j.run(8000)

	time.sleep(10000000000)

	mut con := httpconnection.new(
		name: 'test'
		url:  'http://localhost:8000'
	)!

	request := httpconnection.new_request(
		method: .post
		prefix: 'trigger'
		data:   json.encode(GiteaEvent{
			ref:        '/development'
			repository: Repository{
				full_name: 'freeflowuniverse/crystallib'
				clone_url: 'https://github.com/...'
				url:       'https://github.com/...'
			}
		})
	)!

	response := con.send(request)!
	// j.trigger()

	panic(response)
}

pub fn test_juggler_str() {
	coderoot := if 'CODEROOT' in os.environ() && os.environ()['CODEROOT'] != '' {
		os.environ()['CODEROOT']
	} else {
		'${os.home_dir()}/code'
	}

	mut j := configure(
		name:        '${instance_name}4'
		config_path: '${coderoot}/github/freeflowuniverse/crystallib/crystallib/develop/juggler/testdata'
		host:        '65.21.132.119'
		port:        8000
	)!
	juggler_info := j.info()
	assert juggler_info == '=============== Juggler ===============

User Interface:
- url: http://65.21.132.119:8000
- status: running

Webhook:
- enpoint: 65.21.132.119:8000/trigger
- secret: 

======================================='
}

pub fn test_git_service() ! {
	request := http.new_request(.post, 'http://localhost:8001', '')
	request.add_header(.user_agent, '')
}
