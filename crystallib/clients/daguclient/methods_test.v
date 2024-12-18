module daguclient

import json
import freeflowuniverse.crystallib.clients.httpconnection
import freeflowuniverse.crystallib.osal.dagu as dagu_osal

const username = 'test_username'
const password = 'test_password'
const dag_name = 'methods_test_dag'
const test_dag = dagu_osal.DAG{
	name:  'methods_test_dag'
	steps: [
		dagu_osal.Step{
			name:    'step 1'
			command: 'echo step 1'
		},
		dagu_osal.Step{
			name:    'step 2'
			command: 'echo step 2'
		},
	]
}

__global (
	client DaguClient
)

fn testsuite_begin() {
	client = new(
		username: dagu.username
		password: dagu.password
	)!

	mut d := dagu_osal.new()!
	d.basic_auth(dagu.username, dagu.password) or { panic(err) }
}

fn testsuite_end() {
	client.dag_delete('test_new_dag')!
	client.dag_delete('test_start_dag')!
	client.dag_delete('test_stop_dag')!
	client.dag_delete('test_suspend_dag')!
}

fn test_new_dag() ! {
	client.new_dag(dagu.dag_name, dagu.test_dag)!
}

fn test_start_dag() ! {
	if result := client.start_dag('${dagu.dag_name}_start') {
		assert false
	} else {
		assert true
	}

	client.new_dag('${dagu.dag_name}_start', dagu.test_dag)!
	result := client.start_dag('${dagu.dag_name}_start')!
	assert result == PostDagActionResponse{}
}

fn test_stop_dag() ! {
	if result := client.stop_dag(@FN) {
		assert false
	} else {
		assert true
	}

	client.new_dag(@FN, dagu_osal.DAG{ ...dagu.test_dag, name: @FN })!
	result := client.stop_dag(@FN)!
	assert result == PostDagActionResponse{}
}

fn test_suspend_dag() ! {
	if result := client.suspend_dag(@FN) {
		assert false
	} else {
		assert true
	}

	client.new_dag(@FN, dagu.test_dag)!
	result := client.suspend_dag(@FN)!
	assert result == PostDagActionResponse{}
}
