module griddriver

import os
import strconv
import json
import freeflowuniverse.crystallib.ui.console

pub fn (mut c Client) get_node_twin(node_id u64) !u32 {
	if u32(node_id) in c.node_twin {
		return c.node_twin[u32(node_id)]
	}

	res := os.execute("griddriver node-twin --substrate \"${c.substrate}\"  --node_id ${node_id}")
	if res.exit_code != 0 {
		return error(res.output)
	}

	twin_id := u32(strconv.parse_uint(res.output, 10, 32)!)
	c.node_twin[u32(node_id)] = twin_id
	return twin_id
}

pub fn (mut c Client) get_user_twin() !u32 {
	res := os.execute("griddriver user-twin --mnemonics \"${c.mnemonic}\" --substrate \"${c.substrate}\"")
	if res.exit_code != 0 {
		return error(res.output)
	}

	return u32(strconv.parse_uint(res.output, 10, 32)!)
}

pub fn (mut c Client) create_node_contract(node_id u32, body string, hash string, public_ips u32, solution_provider u64) !u64 {
	console.print_debug('url: ${c.substrate}')
	res := os.execute("griddriver new-node-cn --substrate \"${c.substrate}\" --mnemonics \"${c.mnemonic}\" --node_id ${node_id} --hash \"${hash}\" --public_ips ${public_ips} --body \"${body}\" --solution_provider ${solution_provider}")
	if res.exit_code != 0 {
		return error(res.output)
	}

	return strconv.parse_uint(res.output, 10, 64)!
}

pub fn (mut c Client) create_name_contract(name string) !u64 {
	res := os.execute("griddriver new-name-cn --substrate \"${c.substrate}\" --mnemonics \"${c.mnemonic}\" --name ${name}")
	if res.exit_code != 0 {
		return error(res.output)
	}

	return strconv.parse_uint(res.output, 10, 64)!
}

pub fn (mut c Client) update_node_contract(contract_id u64, body string, hash string) ! {
	res := os.execute("griddriver update-cn --substrate \"${c.substrate}\" --mnemonics \"${c.mnemonic}\" --contract_id ${contract_id} --body \"${body}\" --hash \"${hash}\"")
	if res.exit_code != 0 {
		return error(res.output)
	}
}

pub fn (mut c Client) cancel_contract(contract_id u64) ! {
	res := os.execute("griddriver cancel-cn --substrate \"${c.substrate}\" --mnemonics \"${c.mnemonic}\" --contract_id ${contract_id}")
	if res.exit_code != 0 {
		return error(res.output)
	}
}

pub struct BatchCreateContractData {
pub mut:
	node                 u32
	body                 string
	hash                 string
	public_ips           u32
	solution_provider_id ?u64
	// for name contracts. if set the contract is assumed to be a name contract and other fields are ignored
	name string
}

struct Hamada {
	key []BatchCreateContractData
}

pub fn (mut c Client) batch_create_contracts(contracts_data_ []BatchCreateContractData) ![]u64 {
	mut contracts_data := contracts_data_.clone()
	mut body := ''

	for mut contract in contracts_data {
		if contract.body.len > 0 {
			body = contract.body
		}

		contract.body = ''
	}

	data := json.encode(contracts_data)
	res := os.execute("griddriver batch-create-contract --substrate \"${c.substrate}\" --mnemonics \"${c.mnemonic}\" --contracts-data '${data}' --contracts-body \"${body}\"")

	if res.exit_code != 0 {
		return error(res.output)
	}

	contract_ids := json.decode([]u64, res.output) or {
		return error('Cannot decode the result due to ${err}')
	}
	return contract_ids
}

pub fn (mut c Client) batch_cancel_contracts(contract_ids []u64) ! {
	data := json.encode(contract_ids)
	res := os.execute("griddriver batch-cancel-contract --substrate \"${c.substrate}\" --mnemonics \"${c.mnemonic}\" --contract-ids \"${data}\"")
	if res.exit_code != 0 {
		return error(res.output)
	}
}
