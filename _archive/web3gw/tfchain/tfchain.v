module tfchain

import freeflowuniverse.crystallib.data.rpcwebsocket { RpcWsClient }
import math.unsigned { Uint128, uint128_from_dec_str }

const default_timeout = 500000

@[openrpc: exclude]
@[noinit]
pub struct TfChainClient {
mut:
	client &RpcWsClient
}

@[openrpc: exclude]
pub fn new(mut client RpcWsClient) TfChainClient {
	return TfChainClient{
		client: &client
	}
}

// Generate a mnemonic, create an account on the required network and activate it.
// This will also load the key in the session so all consecutive calls will be using the generated mnemonic.
pub fn (mut t TfChainClient) create_account(network string) !string {
	return t.client.send_json_rpc[[]string, string]('tfchain.CreateAccount', [network],
		default_timeout)!
}

// Load your mnemonic with this call. Choose the network while doing so. The network should be one of:
// mainnet, testnet, qanet, devnet
pub fn (mut t TfChainClient) load(args Load) ! {
	_ := t.client.send_json_rpc[[]Load, string]('tfchain.Load', [args], default_timeout)!
}

// Get the SS58 address of your account
pub fn (mut t TfChainClient) address() !string {
	return t.client.send_json_rpc[[]string, string]('tfchain.Address', []string{}, default_timeout)!
}

// Transfer some amount to some destination. The destionation should be a SS58 address.
pub fn (mut t TfChainClient) transfer(args Transfer) ! {
	_ := t.client.send_json_rpc[[]Transfer, string]('tfchain.Transfer', [args], default_timeout)!
}

// Ask for the balance of an entity using this call. The address should be a SS58 address.
pub fn (mut t TfChainClient) balance(address string) !Uint128 {
	balance := t.client.send_json_rpc[[]string, string]('tfchain.Balance', [address],
		default_timeout)!
	return uint128_from_dec_str(balance)
}

// Get the current height of the chain.
pub fn (mut t TfChainClient) height() !u64 {
	return t.client.send_json_rpc[[]string, u64]('tfchain.Height', []string{}, default_timeout)!
}

// Create a twin. Provide the relay and your public key in this call. The result of this call contains
// your twin id.
pub fn (mut t TfChainClient) create_twin(args CreateTwin) !u32 {
	return t.client.send_json_rpc[[]CreateTwin, u32]('tfchain.CreateTwin', [args], default_timeout)!
}

// Accepts terms and conditions. Provide the document link and document hash while executing this call.
pub fn (mut t TfChainClient) accept_terms_and_conditions(args AcceptTermsAndConditions) ! {
	_ := t.client.send_json_rpc[[]AcceptTermsAndConditions, string]('tfchain.AcceptTermsAndConditions',
		[args], default_timeout)!
}

// Create a farm. Provide a name an a list of public ips if there are any.
pub fn (mut t TfChainClient) create_farm(args CreateFarm) ! {
	_ := t.client.send_json_rpc[[]CreateFarm, string]('tfchain.CreateFarm', [args], default_timeout)!
}

// Create a name contract. Provide the dns name via this call. Returns the id of the contract it
// creates.
pub fn (mut t TfChainClient) create_name_contract(name string) !u64 {
	return t.client.send_json_rpc[[]string, u64]('tfchain.CreateNameContract', [name],
		default_timeout)!
}

// Create a node contract. Provide the node id, body, hash, how many public ips you want to use and
// optionally the solution provider id.
pub fn (mut t TfChainClient) create_node_contract(args CreateNodeContract) !u64 {
	return t.client.send_json_rpc[[]CreateNodeContract, u64]('tfchain.CreateNodeContract',
		[args], default_timeout)!
}

// Create a rent contract. Provide the node id of the node you want to rent and optionally the solution
// provider id.
pub fn (mut t TfChainClient) create_rent_contract(args CreateRentContract) !u64 {
	return t.client.send_json_rpc[[]CreateRentContract, u64]('tfchain.CreateRentContract',
		[args], default_timeout)!
}

// Create a service contract. Provide the SS58 addresses of the service and the consumer.
pub fn (mut t TfChainClient) service_contract_create(args ServiceContractCreate) !u64 {
	return t.client.send_json_rpc[[]ServiceContractCreate, u64]('tfchain.ServiceContractCreate',
		[args], default_timeout)!
}

// Approve a service contract. Provide the contract id to do so. Approving the contract is only allowed
// if the agreement is ready and only by the consumer or the service.
pub fn (mut t TfChainClient) service_contract_approve(contract_id u64) ! {
	_ := t.client.send_json_rpc[[]u64, string]('tfchain.ServiceContractApprove', [
		contract_id,
	], default_timeout)!
}

// Bill a service contract. Provide the contract id, variable_amount and some metadata. The contract
// can only be billed if both service and consumer have approved the contract.
pub fn (mut t TfChainClient) service_contract_bill(args ServiceContractBill) ! {
	_ := t.client.send_json_rpc[[]ServiceContractBill, string]('tfchain.ServiceContractBill',
		[args], default_timeout)!
}

// Cancel a service contract. Provide the contract id to do so.
pub fn (mut t TfChainClient) service_contract_cancel(contract_id u64) ! {
	_ := t.client.send_json_rpc[[]u64, string]('tfchain.ServiceContractCancel', [
		contract_id,
	], default_timeout)!
}

// Reject a service contract. Provide the contract id to do so. Only the service or the consumer is
// allowed to do so and only if it reached a state of agreement. The contract will be deleted when
// at the first call of either the service or the consumer.
pub fn (mut t TfChainClient) service_contract_reject(contract_id u64) ! {
	_ := t.client.send_json_rpc[[]u64, string]('tfchain.ServiceContractReject', [
		contract_id,
	], default_timeout)!
}

// Set the service contract fees. Provide the contract id, the base fee and the variable fee. Only
// the service is allowed to set the fees and only if the contract is not approved by both parties
// yet. The state is set to agreemen if the metadata has been set.
pub fn (mut t TfChainClient) service_contract_set_fees(args SetServiceContractFees) ! {
	_ := t.client.send_json_rpc[[]SetServiceContractFees, string]('tfchain.ServiceContractSetFees',
		[args], default_timeout)!
}

// Set the service contract metadata. Provide contract id and the metadata. Only service or consumer
// can set the metadata. The metadata can be modified by calling this method again but only if the
// contract is not yet approved by both parties. The base fee cannot be 0.
pub fn (mut t TfChainClient) service_contract_set_metadata(args ServiceContractSetMetadata) ! {
	_ := t.client.send_json_rpc[[]ServiceContractSetMetadata, string]('tfchain.ServiceContractSetMetadata',
		[args], default_timeout)!
}

// Cancel a contract. Provide the contract id to do so. Only the creator of the contract can
// cancle the contract. If the contract is a rent contract it can only be canceled if it has no
// more active workloads.
pub fn (mut t TfChainClient) cancel_contract(contract_id u64) ! {
	_ := t.client.send_json_rpc[[]u64, string]('tfchain.CancelContract', [contract_id],
		default_timeout)!
}

// Cancel a list contracts. Provide a list of contract ids to do so. They can only be canceled
// if they were created by the entity calling this function. Rent contracts can not have active
// workloads in order to be canceled.
pub fn (mut t TfChainClient) batch_cancel_contract(contract_ids []u64) ! {
	_ := t.client.send_json_rpc[[][]u64, string]('tfchain.BatchCancelContract', [
		contract_ids,
	], default_timeout)!
}

// Get the current ZOS version
pub fn (mut t TfChainClient) get_zos_version() !string {
	return t.client.send_json_rpc[[]string, string]('tfchain.GetZosVersion', []string{},
		default_timeout)!
}

// Swap TFT tokens to the provided stellar address
pub fn (mut t TfChainClient) swap_to_stellar(args SwapToStellar) ! {
	_ := t.client.send_json_rpc[[]SwapToStellar, string]('tfchain.SwapToStellar', [
		args,
	], default_timeout)!
}

// Await till a transaction is processed on stellar-tfchain bridge that contains a specific memo, that transaction is the result of a bridge from stellar to the loaded tfchain account
pub fn (mut t TfChainClient) await_bridged_from_stellar(memo string) ! {
	_ := t.client.send_json_rpc[[]string, string]('tfchain.AwaitBridgedFromStellar', [
		memo,
	], default_timeout)!
}

// returns twin id via chain address
pub fn (mut t TfChainClient) get_twin_by_pubkey(address string) !u32 {
	return t.client.send_json_rpc[[]string, u32]('tfchain.GetTwinByPubKey', [address],
		default_timeout)!
}

// returns twin info via id
pub fn (mut t TfChainClient) get_twin(id u32) !TwinData {
	return t.client.send_json_rpc[[]u32, TwinData]('tfchain.GetTwin', [id], default_timeout)!
}

pub fn (mut t TfChainClient) get_node(id u32) !NodeData {
	return t.client.send_json_rpc[[]u32, NodeData]('tfchain.GetNode', [id], default_timeout)!
}

pub fn (mut t TfChainClient) get_nodes(farm_id u32) ![]u32 {
	return t.client.send_json_rpc[[]u32, []u32]('tfchain.GetNodes', [farm_id], default_timeout)!
}

pub fn (mut t TfChainClient) get_node_contracts(id u32) ![]u64 {
	return t.client.send_json_rpc[[]u32, []u64]('tfchain.GetNodeContracts', [id], default_timeout)!
}

pub fn (mut t TfChainClient) get_contract(id u64) !ContractData {
	return t.client.send_json_rpc[[]u64, ContractData]('tfchain.GetContract', [id], default_timeout)!
}

pub fn (mut t TfChainClient) get_farm(id u32) !FarmData {
	return t.client.send_json_rpc[[]u32, FarmData]('tfchain.GetFarm', [id], default_timeout)!
}

pub fn (mut t TfChainClient) get_farm_by_name(name string) !u32 {
	return t.client.send_json_rpc[[]string, u32]('tfchain.GetFarmByName', [name], default_timeout)!
}
