module daguclient

import json
import freeflowuniverse.crystallib.clients.httpconnection
import freeflowuniverse.crystallib.ui.console

struct CreateDag {
	action string = 'new' @[required]
	value  string @[required]
}

struct CreateDagResponse {
	dag_id string = 'new' @[json: 'DagID'; required]
}

// Creates a new DAG.
fn (mut client DaguClient) dag_create(name string) !CreateDagResponse {
	request := httpconnection.new_request(
		method: .post
		prefix: 'dags'
		data:   json.encode(CreateDag{ action: 'new', value: name })
	) or { return error('Failed to create request: ${err}') }
	result := client.connection.send(request) or { return error('Failed to send request: ${err}') }

	if !result.is_ok() {
		mut err := json.decode(ApiError, result.data) or {
			return error('Failed to dag create: error: ${result}')
		}
		if '${err}'.trim_space() == '' {
			return error('Failed to send request: ${request}, errorcode:${result.code}')
		}
		return ApiError{
			...err
			code: result.code
		}
	}

	response := json.decode(CreateDagResponse, result.data) or {
		return error('Failed to decode dag response: ${result}')
	}
	return response
}

pub struct ListDagsResponse {
pub:
	dags      []DagListItem @[json: 'DAGs'; required]
	errors    []string      @[json: 'Errors'; required]
	has_error bool          @[json: 'HasError'; required]
}

pub struct DagListItem {
pub:
	file      string    @[json: 'File']
	dir       string    @[json: 'Dir']
	dag       DAG       @[json: 'DAG']
	status    DagStatus @[json: 'Status']
	suspended bool      @[json: 'Suspended']
	error     string    @[json: 'Error']
	error_t   string    @[json: 'ErrorT']
}

// pub struct DAG {
// pub:
// 	group          string     @[json: 'Group']
// 	name           string     @[json: 'Name']
// 	schedule       []Schedule @[json: 'Schedule']
// 	description    string     @[json: 'Description']
// 	params         []string   @[json: 'Params']
// 	default_params string     @[json: 'DefaultParams']
// 	tags           []string   @[json: 'Tags']
// }

pub struct Schedule {
	expression string @[json: 'Expression']
}

pub struct DagStatus {
	request_id  string @[json: 'RequestID']
	name        string @[json: 'Name']
	status      int    @[json: 'Status']
	status_text string @[json: 'StatusText']
	pid         int    @[json: 'PID']
	started_at  string @[json: 'StartedAt']
	finished_at string @[json: 'FinishedAt']
	log         string @[json: 'Log']
	params      string @[json: 'Params']
}

// Creates a new DAG.
pub fn (mut client DaguClient) dags_list() !ListDagsResponse {
	mut request := httpconnection.new_request(
		method: .get
		prefix: 'dags'
	)!

	request.header.add_custom('x-disable-pagination', 'True')!
	request.params['limit'] = '1000'
	request.params['page'] = '1'

	result := client.connection.send(request)!
	console.print_debug('dags_list:\n${result}')
	if !result.is_ok() {
		err := json.decode(ApiError, result.data) or {
			return error('Failed to call dag list: error ${result}')
		}
		return ApiError{
			...err
			code: result.code
		}
	}

	response := json.decode(ListDagsResponse, result.data) or {
		return error('Failed to decodelist dag response ${result}')
	}
	return response
}

@[params]
pub struct PostDagAction {
	action     DagAction @[required]
	value      string
	request_id string
	step       string
	params     string
}

enum DagAction {
	start
	suspend
	stop
	retry
	mark_success
	mark_failed
	save
	rename
}

pub struct PostDagActionResponse {
	new_dag_id string @[json: 'NewDagID']
}

fn (mut client DaguClient) post_dag_action(dag_id string, params PostDagAction) !PostDagActionResponse {
	request := httpconnection.new_request(
		method: .post
		prefix: 'dags/${dag_id}'
		data:   json.encode(params)
	)!

	result := client.connection.send(request)!
	if !result.is_ok() {
		err := json.decode(ApiError, result.data) or {
			return error('Failed to decode post dag action ${result}')
		}
		return ApiError{
			...err
			code: result.code
		}
	}

	response := json.decode(PostDagActionResponse, result.data) or {
		return error('Failed to decode post dag action 2 ${result}')
	}
	return response
}

fn (mut client DaguClient) dag_delete(dag_id string) ! {
	request := httpconnection.new_request(
		method: .delete
		prefix: 'dags/${dag_id}'
	)!

	result := client.connection.send(request)!
	if !result.is_ok() {
		err := json.decode(ApiError, result.data) or {
			return error('Failed to decode dag delete ${result}')
		}
		return ApiError{
			...err
			code: result.code
		}
	}
}
