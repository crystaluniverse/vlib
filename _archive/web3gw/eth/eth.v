module eth

import freeflowuniverse.crystallib.data.rpcwebsocket { RpcWsClient }

const default_timeout = 500000

@[openrpc: exclude]
@[noinit]
pub struct EthClient {
mut:
	client &RpcWsClient
}

@[openrpc: exclude]
pub fn new(mut client RpcWsClient) EthClient {
	return EthClient{
		client: &client
	}
}

// Loads the provided eth key and connects to the provided ethereum network
pub fn (mut e EthClient) load(args Load) ! {
	_ := e.client.send_json_rpc[[]Load, string]('eth.Load', [args], default_timeout)!
}

// Balance of an address, if address is empty the balance of the loaded account will be returned, provide the asset to get the balance of (eth, tft)
pub fn (mut e EthClient) balance(args Balance) !string {
	return e.client.send_json_rpc[[]Balance, string]('eth.Balance', [args], default_timeout)!
}

// Height of the chain for the connected rpc remote
pub fn (mut e EthClient) height() !u64 {
	return e.client.send_json_rpc[[]string, u64]('eth.Height', []string{}, default_timeout)!
}

// Transer an amount of Eth from the loaded account to the destination. The transaction ID is returned.
pub fn (mut e EthClient) transfer(args Transfer) !string {
	return e.client.send_json_rpc[[]Transfer, string]('eth.Transfer', [args], default_timeout)!
}

// Returns the amount that would be received for the given amount where the given amount is defined by the source_asset and the returned value is defined by destination_asset
pub fn (mut e EthClient) quote(args Quote) !string {
	return e.client.send_json_rpc[[]Quote, string]('eth.QuoteEthForTft', [args], default_timeout)!
}

// Swap tokens from one asset to the other (eth to tft, etc)
pub fn (mut e EthClient) swap(args Swap) !string {
	return e.client.send_json_rpc[[]Swap, string]('eth.SwapEthForTft', [args], default_timeout)!
}

// Bridges TFT from your ethereum account to the defined stellar account
pub fn (mut e EthClient) bridge_to_stellar(args BridgeToStellar) !string {
	return e.client.send_json_rpc[[]BridgeToStellar, string]('eth.BridgeToStellar', [
		args,
	], default_timeout)!
}

// Approves the given amount of TFT to be swapped
pub fn (mut e EthClient) approve_tft_spending(amount string) !string {
	return e.client.send_json_rpc[[]string, string]('eth.ApproveTftSpending', [
		amount,
	], default_timeout)!
}

// Returns the amount of TFT approved to be swapped
pub fn (mut e EthClient) get_tft_spending_allowance() !string {
	return e.client.send_json_rpc[[]string, string]('eth.GetTftSpendingAllowance', []string{},
		default_timeout)!
}

// Returns the current loaded eth address
pub fn (mut e EthClient) address() !string {
	return e.client.send_json_rpc[[]string, string]('eth.Address', []string{}, default_timeout)!
}

// Creates and activates a stellar account, the cost to create your account on stellar are paid with ethereum
pub fn (mut e EthClient) create_stellar_account(network string) !string {
	return e.client.send_json_rpc[[]string, string]('eth.CreateStellarAccount', [
		network,
	], default_timeout)!
}

// GetTokenBalance fetches the balance for an erc20 compatible contract
pub fn (mut e EthClient) get_token_balance(contractAddress string) !string {
	return e.client.send_json_rpc[[]string, string]('eth.GetTokenBalance', [
		contractAddress,
	], default_timeout)!
}

// Transfers an erc20 compatible token to a destination address
pub fn (mut e EthClient) transfer_tokens(args TransferTokens) !string {
	return e.client.send_json_rpc[[]TransferTokens, string]('eth.TransferTokens', [
		args,
	], default_timeout)!
}

// Transfers tokens from an account to another account (can be executed by anyone that is approved to be spend)
pub fn (mut e EthClient) transer_tokens_from(args TransferTokensFrom) !string {
	return e.client.send_json_rpc[[]TransferTokensFrom, string]('eth.TransferTokensFrom',
		[args], default_timeout)!
}

// Approves token spending for the given address
pub fn (mut e EthClient) approve_token_spending(args ApproveTokenSpending) !string {
	return e.client.send_json_rpc[[]ApproveTokenSpending, string]('eth.ApproveTokenSpending',
		[args], default_timeout)!
}

// Returns the balance of the given address for the given fungible token contract
pub fn (mut e EthClient) get_fungible_balance(args GetFungibleBalance) !string {
	return e.client.send_json_rpc[[]GetFungibleBalance, string]('eth.GetFungibleBalance',
		[args], default_timeout)!
}

// Returns the owner of the given fungible token
pub fn (mut e EthClient) owner_of_fungible(args OwnerOfFungible) !string {
	return e.client.send_json_rpc[[]OwnerOfFungible, string]('eth.OwnerOfFungible', [
		args,
	], default_timeout)!
}

// Safely transfers the given fungible token
pub fn (mut e EthClient) safe_transfer_fungible(args TransferFungible) !string {
	return e.client.send_json_rpc[[]TransferFungible, string]('eth.SafeTransferFungible',
		[args], default_timeout)!
}

// Transfer the given fungible token from the given address to the given target address
pub fn (mut e EthClient) transfer_fungible(args TransferFungible) !string {
	return e.client.send_json_rpc[[]TransferFungible, string]('eth.TransferFungible',
		[args], default_timeout)!
}

// Sets the fungible approval for the given fungible token
pub fn (mut e EthClient) set_fungible_approval(args SetFungibleApproval) !string {
	return e.client.send_json_rpc[[]SetFungibleApproval, string]('eth.SetFungibleApproval',
		[args], default_timeout)!
}

// Sets the fungible approval for all the given fungible tokens
pub fn (mut e EthClient) set_fungible_approval_for_all(args SetFungibleApprovalForAll) !string {
	return e.client.send_json_rpc[[]SetFungibleApprovalForAll, string]('eth.SetFungibleApprovalForAll',
		[args], default_timeout)!
}

// Returns whether the given address is approved to spend the given tokenId of the given fungible token
pub fn (mut e EthClient) get_approval_for_fungible(args ApprovalForFungible) !bool {
	return e.client.send_json_rpc[[]ApprovalForFungible, bool]('eth.GetApprovalForFungible',
		[args], default_timeout)!
}

// Returns whether the given address is approved to spend all the given fungible tokens
pub fn (mut e EthClient) get_approval_for_all_fungible(args ApprovalForFungible) !bool {
	return e.client.send_json_rpc[[]ApprovalForFungible, bool]('eth.GetApprovalForAllFungible',
		[args], default_timeout)!
}

// Returns the owners of the given multisig contract
pub fn (mut e EthClient) get_multisig_owners(contract_address string) ![]string {
	return e.client.send_json_rpc[[]string, []string]('eth.GetMultisigOwners', [
		contract_address,
	], default_timeout)!
}

// Returns the threshold of the given multisig contract
pub fn (mut e EthClient) get_multisig_threshold(contract_address string) !string {
	return e.client.send_json_rpc[[]string, string]('eth.GetMultisigThreshold', [
		contract_address,
	], default_timeout)!
}

// Adds a new owner to the given multisig contract
pub fn (mut e EthClient) add_multisig_owner(args MultisigOwner) !string {
	return e.client.send_json_rpc[[]MultisigOwner, string]('eth.AddMultisigOwner', [
		args,
	], default_timeout)!
}

// Removes an owner from the given multisig contract
pub fn (mut e EthClient) remove_multisig_owner(args MultisigOwner) !string {
	return e.client.send_json_rpc[[]MultisigOwner, string]('eth.RemoveMultisigOwner',
		[args], default_timeout)!
}

// Approves a hash for the given multisig contract
pub fn (mut e EthClient) approve_hash(args ApproveHash) !string {
	return e.client.send_json_rpc[[]ApproveHash, string]('eth.ApproveHash', [args], default_timeout)!
}

// Returns true if the given hash is approved for the given multisig contract
pub fn (mut e EthClient) is_approved(args ApproveHash) !bool {
	return e.client.send_json_rpc[[]ApproveHash, bool]('eth.IsApproved', [args], default_timeout)!
}

// Initiates a multisig eth transfer.
pub fn (mut e EthClient) initiate_multisig_eth_transfer(args InitiateMultisigEthTransfer) !string {
	return e.client.send_json_rpc[[]InitiateMultisigEthTransfer, string]('eth.InitiateMultisigEthTransfer',
		[args], default_timeout)!
}

// Initiates a multisig token transfer
pub fn (mut e EthClient) initiate_multisig_token_transfer(args InitiateMultisigTokenTransfer) !string {
	return e.client.send_json_rpc[[]InitiateMultisigTokenTransfer, string]('eth.InitiateMultisigTokenTransfer',
		[args], default_timeout)!
}
