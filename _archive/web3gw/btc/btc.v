module btc

import freeflowuniverse.crystallib.data.rpcwebsocket { RpcWsClient }

const default_timeout = 500000

@[openrpc: exclude]
@[noinit]
pub struct BtcClient {
mut:
	client &RpcWsClient
}

@[openrpc: exclude]
pub fn new(mut client RpcWsClient) BtcClient {
	return BtcClient{
		client: &client
	}
}

// Connects to the bitcoin node. This should be the first call to execute.
pub fn (mut c BtcClient) load(params Load) !string {
	return c.client.send_json_rpc[[]Load, string]('btc.Load', [
		params,
	], default_timeout)!
}

// Get the public address of the loaded btc secret
pub fn (mut s BtcClient) address() !string {
	return s.client.send_json_rpc[[]string, string]('btc.Address', []string{}, default_timeout)!
}

// Sends the passed amount to the given address with a comment if provided and returns the hash of the transaction
pub fn (mut c BtcClient) transfer(args Transfer) !string {
	return c.client.send_json_rpc[[]Transfer, string]('btc.Transfer', [args], default_timeout)!
}

// Provides a more accurate estimated fee given an estimation mode.
pub fn (mut c BtcClient) estimate_smart_fee(args EstimateSmartFee) !EstimateSmartFeeResult {
	return c.client.send_json_rpc[[]EstimateSmartFee, EstimateSmartFeeResult]('btc.EstimateSmartFee',
		[args], default_timeout)!
}

// Returns the available balance for the specified account using the default number of minimum confirmations. You can provide * as an account to get the balance of all accounts.
pub fn (mut c BtcClient) get_balance(account string) !i64 {
	return c.client.send_json_rpc[[]string, i64]('btc.GetBalance', [account], default_timeout)!
}

// Returns the number of blocks in the longest block chain.
pub fn (mut c BtcClient) height() !i64 {
	return c.client.send_json_rpc[[]string, i64]('btc.Height', []string{}, default_timeout)!
}

// Returns the hash of the block in the best block chain at the given height.
pub fn (mut c BtcClient) get_block_hash(block_height i64) !string {
	return c.client.send_json_rpc[[]i64, string]('btc.GetBlockHash', [block_height], default_timeout)!
}

// Returns the block count.
pub fn (mut c BtcClient) get_block_count() !i64 {
	return c.client.send_json_rpc[[]string, i64]('btc.GetBlockCount', []string{}, default_timeout)!
}

// Returns block statistics given the hash of that block.
pub fn (mut c BtcClient) get_block_stats(hash string) !GetBlockStatsResult {
	return c.client.send_json_rpc[[]string, GetBlockStatsResult]('btc.GetBlockStats',
		[hash], default_timeout)!
}

// Returns information about a block and its transactions given the hash of that block.
pub fn (mut c BtcClient) get_block_verbose_tx(hash string) !GetBlockVerboseTxResult {
	return c.client.send_json_rpc[[]string, GetBlockVerboseTxResult]('btc.GetBlockVerboseTx',
		[hash], default_timeout)!
}

// Returns statistics about the total number and rate of transactions in the chain.
// Providing the arguments will reduce the amount of blocks to calculate the statistics on.
pub fn (mut c BtcClient) get_chain_tx_stats(args GetChainTxStats) !GetChainTxStatsResult {
	return c.client.send_json_rpc[[]GetChainTxStats, GetChainTxStatsResult]('btc.GetChainTxStats',
		[args], default_timeout)!
}

// Returns the proof-of-work difficulty as a multiple of the minimum difficulty.
pub fn (mut c BtcClient) get_difficulty() !f64 {
	return c.client.send_json_rpc[[]string, f64]('btc.GetDifficulty', []string{}, default_timeout)!
}

// Returns mining information.
pub fn (mut c BtcClient) get_mining_info() !GetMiningInfoResult {
	return c.client.send_json_rpc[[]string, GetMiningInfoResult]('btc.GetMiningInfo',
		[]string{}, default_timeout)!
}

// Returns a new address. The returned string will be the encoded address (format will be based on the chain's parameters).
pub fn (mut c BtcClient) get_new_address(account string) !string {
	return c.client.send_json_rpc[[]string, string]('btc.GetNewAddress', [account], default_timeout)!
}

// Returns data about known node addresses.
pub fn (mut c BtcClient) get_node_addresses() ![]GetNodeAddressesResult {
	return c.client.send_json_rpc[[]string, []GetNodeAddressesResult]('btc.GetNodeAddresses',
		[]string{}, default_timeout)!
}

// Returns data about each connected network peer.
pub fn (mut c BtcClient) get_peer_info() ![]GetPeerInfoResult {
	return c.client.send_json_rpc[[]string, []GetPeerInfoResult]('btc.GetPeerInfo', []string{},
		default_timeout)!
}

// Returns a transaction given its hash.
pub fn (mut c BtcClient) get_raw_transaction(tx_hash string) !Transaction {
	return c.client.send_json_rpc[[]string, Transaction]('btc.GetRawTransaction', [
		tx_hash,
	], default_timeout)!
}
