module grid

import net.http
import json
import x.json2
import log
import freeflowuniverse.crystallib.threefold.grid.models

pub struct GraphQl {
	url string
pub mut:
	logger log.Log
}

pub struct Contract {
pub:
	contract_id     string @[json: contractID]
	deployment_data string @[json: deploymentData]
	state           string
	node_id         u32 @[json: nodeID]
	name            string
}

pub struct Contracts {
pub mut:
	name_contracts []Contract @[json: nameContracts]
	node_contracts []Contract @[json: nodeContracts]
	rent_contracts []Contract @[json: rentContracts]
}

// contractsList, err := c.ListContractsByTwinID([]string{"Created, GracePeriod"})
pub fn (mut g GraphQl) list_twin_contracts(twin_id u32, states []string) !Contracts {
	state := '[${states.join(', ')}]'

	options := '(where: {twinID_eq: ${twin_id}, state_in: ${state}}, orderBy: twinID_ASC)'
	name_contracts_count := g.get_item_total_count('nameContracts', options)!
	node_contracts_count := g.get_item_total_count('nodeContracts', options)!
	rent_contracts_count := g.get_item_total_count('rentContracts', options)!
	contracts_data := g.query('query getContracts(\$nameContractsCount: Int!, \$nodeContractsCount: Int!, \$rentContractsCount: Int!){
            nameContracts(where: {twinID_eq: ${twin_id}, state_in: ${state}}, limit:  \$nameContractsCount) {
              contractID
              state
              name
            }
            nodeContracts(where: {twinID_eq: ${twin_id}, state_in: ${state}}, limit: \$nodeContractsCount) {
              contractID
              deploymentData
              state
              nodeID
            }
            rentContracts(where: {twinID_eq: ${twin_id}, state_in: ${state}}, limit: \$rentContractsCount) {
              contractID
              state
              nodeID
            }
          }', // map[string]u32{}
	 {
		'nodeContractsCount': node_contracts_count
		'nameContractsCount': name_contracts_count
		'rentContractsCount': rent_contracts_count
	})!

	return json.decode(Contracts, contracts_data.str())!
}

// GetItemTotalCount return count of items
fn (g GraphQl) get_item_total_count(item_name string, options string) !u32 {
	count_body := 'query { items: ${item_name}Connection${options} { count: totalCount } }'
	request_body := {
		'query': count_body
	}
	json_body := json.encode(request_body)

	resp := http.post_json(g.url, json_body)!
	query_data := json2.raw_decode(resp.body)!
	query_map := query_data.as_map()

	errors := query_map['errors'] or { '' }.str()
	if errors != '' {
		return error('graphQl query error: ${errors}')
	}

	data := query_map['data']! as map[string]json2.Any
	items := data['items']! as map[string]json2.Any
	count := u32(items['count']!.int())
	return count
}

struct QueryRequest {
	query     string
	variables map[string]u32
}

// Query queries graphql
fn (g GraphQl) query(body string, variables map[string]u32) !map[string]json2.Any {
	mut request_body := QueryRequest{
		query:     body
		variables: variables
	}
	json_body := json.encode(request_body)
	resp := http.post_json(g.url, json_body)!

	query_data := json2.raw_decode(resp.body)!
	data_map := query_data.as_map()
	result := data_map['data']!.as_map()
	return result
}

pub fn (mut g GraphQl) get_contract_by_project_name(mut deployer Deployer, project_name string) !Contracts {
	mut contracts := Contracts{}

	g.logger.debug('Getting user twin')
	twin_id := deployer.client.get_user_twin()!
	g.logger.debug('Getting twin ${twin_id} contracts...')

	contract_list := g.list_twin_contracts(twin_id, ['Created', 'GracePeriod'])!

	g.logger.debug('filtering contract with project name: ${project_name}')
	for contract in contract_list.node_contracts {
		data := json.decode(models.DeploymentData, contract.deployment_data)!
		if data.project_name == project_name {
			contracts.node_contracts << contract
		}
	}
	g.logger.debug('filtering name contracts related to project name: ${project_name}')
	gw_workload := name_gw_in_node_contract(mut deployer, contracts.node_contracts)!
	contracts.name_contracts << filter_name_contract(contract_list.name_contracts, gw_workload)!
	return contracts
}

fn name_gw_in_node_contract(mut deployer Deployer, node_contracts []Contract) ![]models.Workload {
	mut gw_workloads := []models.Workload{}
	for contract in node_contracts {
		dl := deployer.get_deployment(contract.contract_id.u64(), contract.node_id) or {
			return error("Couldn't get deployment workloads: ${err}")
		}
		for wl in dl.workloads {
			if wl.type_ == models.workload_types.gateway_name {
				gw_workloads << wl
			}
		}
	}
	return gw_workloads
}

fn filter_name_contract(name_contract []Contract, gw_workload []models.Workload) ![]Contract {
	mut contracts := []Contract{}
	for contract in name_contract {
		for wl in gw_workload {
			if wl.name == contract.name {
				contracts << contract
			}
		}
	}
	return contracts
}
