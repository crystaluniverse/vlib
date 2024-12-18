module gridproxy

// client library for threefold gridproxy API.
import json
import math
import freeflowuniverse.crystallib.threefold.gridproxy.model { Bill, Contract, ContractFilter, ContractIterator, Farm, FarmFilter, FarmIterator, GridStat, Node, NodeFilter, NodeIterator, NodeStats, Node_, StatFilter, Twin, TwinFilter, TwinIterator }
import freeflowuniverse.crystallib.ui.console

/*
all errors returned by the gridproxy API or the client are wrapped in a standard `Error` object with two fields.
{
	msg string
	code int // could be API call error code or client error code
}

`code` is an error code that can be used to identify the error.
in API call errors, `code` represents the HTTP status code. (100..599)

Client errors codes are represented by numbers in the range of 1..99
currently, the following client error codes are used:
id not found error code: 4
json parsing error code: 10
http client error code: 11
invalid response from server (e.g. empty response) error code: 24
*/
// clinet error codes
const err_not_found = 4
const err_json_parse = 10
const err_http_client = 11
const err_invalid_resp = 24
const err_grid_client = 30

// get_node_by_id fetchs specific node information by node id.
//
// * `node_id` (u64): node id.
//
// returns: `Node` or `Error`.
pub fn (mut c GridProxyClient) get_node_by_id(node_id u64) !Node {
	// needed to allow to use threads
	mut http_client := c.http_client.clone()!

	res := http_client.send(prefix: 'nodes/', id: '${node_id}') or {
		return error_with_code('http client error: ${err.msg()}', err_http_client)
	}

	if !res.is_ok() {
		return error_with_code(res.data, res.code)
	}

	if res.data == '' {
		return error_with_code('empty response', err_invalid_resp)
	}

	node := json.decode(Node, res.data) or {
		return error_with_code('error to get jsonstr for node data, json decode: node id: ${node_id}, data: ${res.data}',
			err_json_parse)
	}
	return node
}

// get_node_stats_by_id fetchs specific node statistics by node id.
//
// * `node_id` (u64): node id.
//
// returns: `Node_stats` or `Error`.
pub fn (mut c GridProxyClient) get_node_stats_by_id(node_id u64) !NodeStats {
	// needed to allow to use threads
	mut http_client := c.http_client.clone()!

	res := http_client.send(prefix: 'nodes/', id: '${node_id}/statistics') or {
		return error_with_code('http client error: ${err.msg()}', err_http_client)
	}

	if !res.is_ok() {
		return error_with_code(res.data, res.code)
	}

	if res.data == '' {
		return error_with_code('empty response', err_invalid_resp)
	}

	node_stats := json.decode(NodeStats, res.data) or {
		return error_with_code('error to get jsonstr for node data, json decode: node id: ${node_id}, data: ${res.data}',
			err_json_parse)
	}
	return node_stats
}

// get_gateway_by_id fetchs specific gateway information by node id.
//
// * `node_id` (u64): node id.
//
// returns: `Node` or `Error`.
pub fn (mut c GridProxyClient) get_gateway_by_id(node_id u64) !Node {
	// needed to allow to use threads
	mut http_client := c.http_client.clone()!

	res := http_client.send(prefix: 'gateways/', id: '${node_id}') or {
		return error_with_code('http client error: ${err.msg()}', err_http_client)
	}

	if !res.is_ok() {
		return error_with_code(res.data, res.code)
	}

	if res.data == '' {
		return error_with_code('empty response', err_invalid_resp)
	}

	node := json.decode(Node, res.data) or {
		return error_with_code('error to get jsonstr for gateway data, json decode: gateway id: ${node_id}, data: ${res.data}',
			err_json_parse)
	}
	return node
}

// get_nodes fetchs nodes information and public configurations with pagination.
//
// * `available_for` (u64): Available for twin id. [optional].
// * `certification_type` (string): Certificate type NotCertified, Silver or Gold. [optional].
// * `city_contains` (string): Node partial city filter. [optional].
// * `city` (string): Node city filter. [optional].
// * `country_contains` (string): Node partial country filter. [optional].
// * `country` (string): Node country filter. [optional].
// * `dedicated` (bool): Set to true to get the dedicated nodes only. [optional].
// * `domain` (string): Set to true to filter nodes with domain. [optional].
// * `farm_ids` ([]u64): List of farm ids. [optional].
// * `farm_name_contains` (string): Get nodes for specific farm. [optional].
// * `farm_name` (string): Get nodes for specific farm. [optional].
// * `free_hru` (u64): Min free reservable hru in bytes. [optional].
// * `free_ips` (u64): Min number of free ips in the farm of the node. [optional].
// * `free_mru` (u64): Min free reservable mru in bytes. [optional].
// * `free_sru` (u64): Min free reservable sru in bytes. [optional].
// * `gpu_available` (bool): Filter nodes that have available GPU. [optional].
// * `gpu_device_id` (string): Filter nodes based on GPU device ID. [optional].
// * `gpu_device_name` (string): Filter nodes based on GPU device partial name. [optional].
// * `gpu_vendor_id` (string): Filter nodes based on GPU vendor ID. [optional].
// * `gpu_vendor_name` (string): Filter nodes based on GPU vendor partial name. [optional].
// * `has_gpu`: Filter nodes on whether they have GPU support or not. [optional].
// * `ipv4` (string): Set to true to filter nodes with ipv4. [optional].
// * `ipv6` (string): Set to true to filter nodes with ipv6. [optional].
// * `node_id` (u64): Node id. [optional].
// * `page` (u64): Page number. [optional].
// * `rentable` (bool): Set to true to filter the available nodes for renting. [optional].
// * `rented_by` (u64): Rented by twin id. [optional].
// * `ret_count` (bool): Set nodes' count on headers based on filter. [optional].
// * `size` (u64): Max result per page. [optional].
// * `status` (string): Node status filter, set to 'up' to get online nodes only. [optional].
// * `total_cru` (u64): Min total cru in bytes. [optional].
// * `total_hru` (u64): Min total hru in bytes. [optional].
// * `total_mru` (u64): Min total mru in bytes. [optional].
// * `total_sru` (u64): Min total sru in bytes. [optional].
// * `twin_id` (u64): Twin id. [optional].
//
// returns: `[]Node` or `Error`.
pub fn (mut c GridProxyClient) get_nodes(params NodeFilter) ![]Node {
	// needed to allow to use threads
	mut http_client := c.http_client.clone()!
	params_map := params.to_map()
	res := http_client.send(prefix: 'nodes/', params: params_map) or {
		return error_with_code('http client error: ${err.msg()}', err_http_client)
	}

	if !res.is_ok() {
		return error_with_code(res.data, res.code)
	}

	if res.data == '' {
		return error_with_code('empty response', err_invalid_resp)
	}

	nodes_ := json.decode([]Node_, res.data) or {
		return error_with_code('error to get jsonstr for node list data, json decode: node filter: ${params_map}, data: ${res.data}',
			err_json_parse)
	}
	nodes := nodes_.map(it.with_nested_capacity())
	return nodes
}

// get_gateways fetchs gateways information and public configurations and domains with pagination.
//
// * `available_for` (u64): Available for twin id. [optional].
// * `certification_type` (string): Certificate type NotCertified, Silver or Gold. [optional].
// * `city_contains` (string): Node partial city filter. [optional].
// * `city` (string): Node city filter. [optional].
// * `country_contains` (string): Node partial country filter. [optional].
// * `country` (string): Node country filter. [optional].
// * `dedicated` (bool): Set to true to get the dedicated nodes only. [optional].
// * `domain` (bool): Set to true to filter nodes with domain. [optional].
// * `farm_ids` ([]u64): List of farm ids. [optional].
// * `farm_name_contains` (string): Get nodes for specific farm. [optional].
// * `farm_name` (string): Get nodes for specific farm. [optional].
// * `free_hru` (u64): Min free reservable hru in bytes. [optional].
// * `free_ips` (u64): Min number of free ips in the farm of the node. [optional].
// * `free_mru` (u64): Min free reservable mru in bytes. [optional].
// * `free_sru` (u64): Min free reservable sru in bytes. [optional].
// * `gpu_available` (bool): Filter nodes that have available GPU. [optional].
// * `gpu_device_id` (string): Filter nodes based on GPU device ID. [optional].
// * `gpu_device_name` (string): Filter nodes based on GPU device partial name. [optional].
// * `gpu_vendor_id` (string): Filter nodes based on GPU vendor ID. [optional].
// * `gpu_vendor_name` (string): Filter nodes based on GPU vendor partial name. [optional].
// * `has_gpu`: Filter nodes on whether they have GPU support or not. [optional].
// * `ipv4` (string): Set to true to filter nodes with ipv4. [optional].
// * `ipv6` (string): Set to true to filter nodes with ipv6. [optional].
// * `node_id` (u64): Node id. [optional].
// * `page` (u64): Page number. [optional].
// * `rentable` (bool): Set to true to filter the available nodes for renting. [optional].
// * `rented_by` (u64): Rented by twin id. [optional].
// * `ret_count` (bool): Set nodes' count on headers based on filter. [optional].
// * `size` (u64): Max result per page. [optional].
// * `status` (string): Node status filter, set to 'up' to get online nodes only. [optional].
// * `total_cru` (u64): Min total cru in bytes. [optional].
// * `total_hru` (u64): Min total hru in bytes. [optional].
// * `total_mru` (u64): Min total mru in bytes. [optional].
// * `total_sru` (u64): Min total sru in bytes. [optional].
// * `twin_id` (u64): Twin id. [optional].
//
// returns: `[]Node` or `Error`.
pub fn (mut c GridProxyClient) get_gateways(params NodeFilter) ![]Node {
	// needed to allow to use threads
	mut http_client := c.http_client.clone()!
	params_map := params.to_map()
	res := http_client.send(prefix: 'gateways/', params: params_map) or {
		return error_with_code('http client error: ${err.msg()}', err_http_client)
	}

	if !res.is_ok() {
		return error_with_code(res.data, res.code)
	}

	if res.data == '' {
		return error_with_code('empty response', err_invalid_resp)
	}

	nodes_ := json.decode([]Node_, res.data) or {
		return error_with_code('error to get jsonstr for gateways list data, json decode: gateway filter: ${params_map}, data: ${res.data}',
			err_json_parse)
	}
	nodes := nodes_.map(it.with_nested_capacity())
	return nodes
}

// get_stats fetchs stats about the grid.
//
// * `status` (string): Node status filter, set to 'up' to get online nodes only.. [optional].
//
// returns: `GridStat` or `Error`.
pub fn (mut c GridProxyClient) get_stats(filter StatFilter) !GridStat {
	// needed to allow to use threads
	mut http_client := c.http_client.clone()!
	mut params_map := map[string]string{}
	params_map['status'] = match filter.status {
		.all { '' }
		.online { 'up' }
	}

	res := http_client.send(prefix: 'stats/', params: params_map) or {
		return error_with_code('http client error: ${err.msg()}', err_http_client)
	}

	if !res.is_ok() {
		return error_with_code(res.data, res.code)
	}

	if res.data == '' {
		return error_with_code('empty response', err_invalid_resp)
	}

	stats := json.decode(GridStat, res.data) or {
		return error_with_code('error to get jsonstr for grid stats data, json decode: stats filter: ${params_map}, data: ${res.data}',
			err_json_parse)
	}
	return stats
}

// get_twins fetchs twins information with pagaination.
//
// * `account_id` (string): Account address. [optional].
// * `page` (u64): Page number. [optional].
// * `public_key` (string): twin public key used for e2e encryption. [optional].
// * `relay` (string): relay domain name. [optional].
// * `ret_count` (bool): Set farms' count on headers based on filter. [optional].
// * `size` (u64): Max result per page. [optional].
// * `twin_id` (u64): Twin id. [optional].
//
// returns: `[]Twin` or `Error`.
pub fn (mut c GridProxyClient) get_twins(params TwinFilter) ![]Twin {
	// needed to allow to use threads
	mut http_client := c.http_client.clone()!
	params_map := params.to_map()
	res := http_client.send(prefix: 'twins/', params: params_map) or {
		return error_with_code('http client error: ${err.msg()}', err_http_client)
	}

	if !res.is_ok() {
		return error_with_code(res.data, res.code)
	}

	if res.data == '' {
		return error_with_code('empty response', err_invalid_resp)
	}

	twins := json.decode([]Twin, res.data) or {
		return error_with_code('error to get jsonstr for twin list data, json decode: twin filter: ${params_map}, data: ${res.data}',
			err_json_parse)
	}
	return twins
}

// get_contracts fetchs contracts information with pagination.
//
// * `contract_id` (u64): Contract id. [optional].
// * `contract_type` (string): [optional].
// * `deployment_data` (string): Contract deployment data in case of 'node' contracts. [optional].
// * `deployment_hash` (string): Contract deployment hash in case of 'node' contracts. [optional].
// * `name` (string): Contract name in case of 'name' contracts. [optional].
// * `node_id` (u64): Node id which contract is deployed on in case of ('rent' or 'node' contracts). [optional].
// * `number_of_public_ips` (u64): Min number of public ips in the 'node' contract. [optional].
// * `page` (u64): Page number. [optional].
// * `randomize` (bool): [optional].
// * `ret_count` (bool): Set farms' count on headers based on filter. [optional].
// * `size` (u64): Max result per page. [optional].
// * `state` (string): Contract state 'Created', or 'Deleted'. [optional].
// * `twin_id` (u64): Twin id. [optional].
// * `type` (string): Contract type 'node', 'name', or 'rent'. [optional].
//
// * returns: `[]Contract` or `Error`.
pub fn (mut c GridProxyClient) get_contracts(params ContractFilter) ![]Contract {
	// needed to allow to use threads
	mut http_client := c.http_client.clone()!
	params_map := params.to_map()
	res := http_client.send(prefix: 'contracts/', params: params_map) or {
		return error_with_code('http client error: ${err.msg()}', err_http_client)
	}

	if !res.is_ok() {
		return error_with_code(res.data, res.code)
	}

	if res.data == '' {
		return error_with_code('empty response', err_invalid_resp)
	}

	contracts := json.decode([]Contract, res.data) or {
		return error_with_code('error to get jsonstr for contract list data, json decode: contract filter: ${params_map}, data: ${res.data}',
			err_json_parse)
	}
	return contracts
}

pub fn (mut c GridProxyClient) get_contract_bill(contract_id u64) ![]Bill {
	// needed to allow to use threads
	mut http_client := c.http_client.clone()!

	res := http_client.send(prefix: 'contracts/', id: '${contract_id}/bills') or {
		return error_with_code('http client error: ${err.msg()}', err_http_client)
	}

	if !res.is_ok() {
		return error_with_code(res.data, res.code)
	}

	if res.data == '' {
		return error_with_code('empty response', err_invalid_resp)
	}
	console.print_debug(res.data)
	bills := json.decode([]Bill, res.data) or {
		return error_with_code('error to get jsonstr for billing data, json decode: contract_id id: ${contract_id}, data: ${res.data}',
			err_json_parse)
	}
	return bills
}

pub fn (mut c GridProxyClient) get_contract_hourly_bill(contract_id u64) !f64 {
	bills := c.get_contract_bill(contract_id)!
	if bills.len == 0 {
		return f64(0)
	}
	mut duration := u64(0)
	if bills.len >= 2 {
		duration = (bills[0].timestamp - bills[1].timestamp) / 3600 // one hour
	} else if bills.len == 1 {
		contracts := c.get_contracts(contract_id: contract_id)!
		if contracts.len > 0 {
			duration = (bills[0].timestamp - contracts[0].created_at) / 3600
		}
	}
	if duration > 0 {
		return bills[0].amount_billed / duration / math.pow(10, 7)
	}
	return f64(0)
}

// get_farms fetchs farms information and public ips.
//
// * `certification_type` (string): Certificate type DIY or Certified. [optional].
// * `country` (string): Farm country. [optional].
// * `dedicated` (bool): Farm is dedicated. [optional].
// * `farm_id` (u64): Farm id. [optional].
// * `free_ips` (u64): Min number of free ips in the farm. [optional].
// * `name_contains` (string): Farm name contains. [optional].
// * `name` (string): Farm name. [optional].
// * `node_available_for` (u64): Twin ID of user for whom there is at least one node that is available to be deployed to in the farm. [optional].
// * `node_certified` (bool): True for farms who have at least one certified node. [optional].
// * `node_free_hru` (u64): Min free reservable hru for at least a single node that belongs to the farm, in bytes. [optional].
// * `node_free_mru` (u64): Min free reservable mru for at least a single node that belongs to the farm, in bytes. [optional].
// * `node_free_sru` (u64): Min free reservable sru for at least a single node that belongs to the farm, in bytes. [optional].
// * `node_has_gpu` (bool): True for farms who have at least one node with a GPU
// * `node_rented_by` (u64): Twin ID of user who has at least one rented node in the farm
// * `node_status` (string): Node status for at least a single node that belongs to the farm
// * `page` (u64): Page number. [optional].
// * `pricing_policy_id` (u64): Pricing policy id. [optional].
// * `randomize` (bool): [optional].
// * `ret_count` (bool): Set farms' count on headers based on filter. [optional].
// * `size` (u64): Max result per page. [optional].
// * `stellar_address` (string): Farm stellar_address. [optional].
// * `total_ips` (u64): Min number of total ips in the farm. [optional].
// * `twin_id` (u64): Twin id associated with the farm. [optional].
// * `version` (u64): Farm version. [optional].
//
// returns: `[]Farm` or `Error`.
pub fn (mut c GridProxyClient) get_farms(params FarmFilter) ![]Farm {
	// needed to allow to use threads
	mut http_client := c.http_client.clone()!
	params_map := params.to_map()
	res := http_client.send(prefix: 'farms/', params: params_map) or {
		return error_with_code('http client error: ${err.msg()}', err_http_client)
	}

	if !res.is_ok() {
		return error_with_code(res.data, res.code)
	}

	if res.data == '' {
		return error_with_code('empty response', err_invalid_resp)
	}

	farms := json.decode([]Farm, res.data) or {
		return error_with_code('error to get jsonstr for farm list data, json decode: farm filter: ${params_map}, data: ${res.data}',
			err_json_parse)
	}
	return farms
}

// is_pingable checks if API server is reachable and responding.
//
// returns: bool, `true` if API server is reachable and responding, `false` otherwise
pub fn (mut c GridProxyClient) is_pingable() !bool {
	mut http_client := c.http_client.clone()!
	res := http_client.send(prefix: 'ping/') or { return false }
	if !res.is_ok() {
		return false
	}
	health_map := json.decode(map[string]string, res.data) or { return false }

	if health_map['ping'] != 'pong' {
		return false
	}

	return true
}

// Iterators have the next() method, which returns the next page of the objects.
// to be used in a loop to get all available results, or to lazely traverse pages till a specific condition is met.

// get_nodes_iterator creates an iterator through node pages with custom filter
fn (mut c GridProxyClient) get_nodes_iterator(filter NodeFilter) NodeIterator {
	return NodeIterator{filter, c.get_nodes}
}

// get_gateways_iterator creates an iterator through gateway pages with custom filter
fn (mut c GridProxyClient) get_gateways_iterator(filter NodeFilter) NodeIterator {
	return NodeIterator{filter, c.get_gateways}
}

// get_farms_iterator creates an iterator through farms pages with custom filter
fn (mut c GridProxyClient) get_farms_iterator(filter FarmFilter) FarmIterator {
	return FarmIterator{filter, c.get_farms}
}

// get_twins_iterator creates an iterator through twin pages with custom filter
fn (mut c GridProxyClient) get_twins_iterator(filter TwinFilter) TwinIterator {
	return TwinIterator{filter, c.get_twins}
}

// get_contracts_iterator creates an iterator through contracts pages with custom filter
fn (mut c GridProxyClient) get_contracts_iterator(filter ContractFilter) ContractIterator {
	return ContractIterator{filter, c.get_contracts}
}
