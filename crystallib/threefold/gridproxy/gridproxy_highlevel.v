module gridproxy

import freeflowuniverse.crystallib.threefold.gridproxy.model { Contract, ContractFilter, Farm, FarmFilter, Node, NodeFilter, ResourceFilter, Twin }

// fetch specific twin information by twin id.
//
// * `twin_id`: twin id.
//
// returns: `Twin` or `Error`.
pub fn (mut c GridProxyClient) get_twin_by_id(twin_id u64) !Twin {
	twins := c.get_twins(twin_id: twin_id) or {
		return error_with_code('http client error: ${err.msg()}', err_http_client)
	}
	if twins.len == 0 {
		return error_with_code('no twin found for id: ${twin_id}', err_not_found)
	}
	return twins[0]
}

// fetch specific twin information by account.
//
// * `account_id`: account id.
//
// returns: `Twin` or `Error`.
pub fn (mut c GridProxyClient) get_twin_by_account(account_id string) !Twin {
	twins := c.get_twins(account_id: account_id) or {
		return error_with_code('http client error: ${err.msg()}', err_http_client)
	}
	if twins.len == 0 {
		return error_with_code('no twin found for account_id: ${account_id}', err_not_found)
	}
	return twins[0]
}

// fetch specific farm information by id.
//
// * `farm_id`: farm id.
//
// returns: `Farm` or `Error`.
pub fn (mut c GridProxyClient) get_farm_by_id(farm_id u64) !Farm {
	farms := c.get_farms(farm_id: farm_id) or {
		return error_with_code('http client error: ${err.msg()}', err_http_client)
	}
	if farms.len == 0 {
		return error_with_code('no farm found for id: ${farm_id}', err_not_found)
	}
	return farms[0]
}

// fetch specific farm information by farm name.
//
// * `farm_name`: farm name.
//
// returns: `Farm` or `Error`.
pub fn (mut c GridProxyClient) get_farm_by_name(farm_name string) !Farm {
	farms := c.get_farms(name: farm_name) or {
		return error_with_code('http client error: ${err.msg()}', err_http_client)
	}
	if farms.len == 0 {
		return error_with_code('no farm found with name: ${farm_name}', err_not_found)
	}
	return farms[0]
}

// get_farms_by_twin_id returns iterator over all farms information associated with specific twin.
//
// * `twin_id`: twin id.
//
// returns: `FarmIterator`.
pub fn (mut c GridProxyClient) get_farms_by_twin_id(twin_id u64) []Farm {
	mut filter := FarmFilter{
		twin_id: twin_id
	}
	mut iter := c.get_farms_iterator(filter)
	mut result := []Farm{}
	for f in iter {
		result << f
	}
	return result
}

// get_contracts_by_twin_id returns iterator over all contracts owned by specific twin.
//
// * `twin_id`: twin id.
//
// returns: `ContractIterator`.
pub fn (mut c GridProxyClient) get_contracts_by_twin_id(twin_id u64) []Contract {
	/*
	contracts := c.get_contracts(twin_id: twin_id) or {
		return error_with_code('http client error: $err.msg()', gridproxy.err_http_client)
	}*/
	mut filter := ContractFilter{
		twin_id: twin_id
	}
	mut iter := c.get_contracts_iterator(filter)
	mut result := []Contract{}
	for f in iter {
		result << f
	}
	return result
}

// get_active_contracts returns iterator over `created` contracts owned by specific twin.
//
// * `twin_id`: twin id.
//
// returns: `ContractIterator`.
pub fn (mut c GridProxyClient) get_contracts_active(twin_id u64) []Contract {
	/*
	contracts := c.get_contracts(twin_id: twin_id) or {
		return error_with_code('http client error: $err.msg()', gridproxy.err_http_client)
	}*/
	mut filter := ContractFilter{
		twin_id: twin_id
		state:   'created'
	}

	mut iter := c.get_contracts_iterator(filter)
	mut result := []Contract{}
	for f in iter {
		result << f
	}
	return result
}

// get_contracts_by_node_id returns iterator over all contracts deployed on specific node.
//
// * `node_id`: node id.
//
// returns: `ContractIterator`.
pub fn (mut c GridProxyClient) get_contracts_by_node_id(node_id u64) []Contract {
	/*
	contracts := c.get_contracts(node_id: node_id) or {
		return error_with_code('http client error: $err.msg()', gridproxy.err_http_client)
	}*/
	mut filter := ContractFilter{
		node_id: node_id
	}
	mut iter := c.get_contracts_iterator(filter)
	mut result := []Contract{}
	for f in iter {
		result << f
	}
	return result
}

// get_nodes_has_resources returns iterator over all nodes with specific minimum free reservable resources.
//
// * `free_ips` (u64): minimum free ips. [optional].
// * `free_mru_gb` (u64): minimum free mru in GB. [optional].
// * `free_sru_gb` (u64): minimum free sru in GB. [optional].
// * `free_hru_gb` (u64): minimum free hru in GB. [optional].
//
// returns: `NodeIterator`.
fn (mut c GridProxyClient) get_nodes_has_resources(filter ResourceFilter) []Node {
	mut filter_ := NodeFilter{
		free_ips:  filter.free_ips
		free_mru:  filter.free_mru_gb * (1204 * 1204 * 1204)
		free_sru:  filter.free_sru_gb * (1204 * 1204 * 1204)
		free_hru:  filter.free_hru_gb * (1204 * 1204 * 1204)
		total_cru: filter.free_cpu
	}
	mut iter := c.get_nodes_iterator(filter_)
	mut result := []Node{}
	for f in iter {
		result << f
	}
	return result
}
