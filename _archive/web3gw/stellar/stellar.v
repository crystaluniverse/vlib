module stellar

import freeflowuniverse.crystallib.data.rpcwebsocket { RpcWsClient }

const default_timeout = 500000

@[openrpc: exclude]
@[noinit]
pub struct StellarClient {
mut:
	client &RpcWsClient
}

@[openrpc: exclude]
pub fn new(mut client RpcWsClient) StellarClient {
	return StellarClient{
		client: &client
	}
}

// Load a client, connecting to the rpc endpoint at the given network and loading a keypair from the given secret.
pub fn (mut s StellarClient) load(args Load) ! {
	_ := s.client.send_json_rpc[[]Load, string]('stellar.Load', [args], default_timeout)!
}

// Creates an account on the provided network and returns the seed. Consecutive calls will be using the newly created account.
pub fn (mut s StellarClient) create_account(network string) !string {
	return s.client.send_json_rpc[[]string, string]('stellar.CreateAccount', [network],
		default_timeout)!
}

// Get the public address of the loaded stellar secret
pub fn (mut s StellarClient) address() !string {
	return s.client.send_json_rpc[[]string, string]('stellar.Address', []string{}, default_timeout)!
}

// Return a limited amount of transactions bound to a specific account
pub fn (mut s StellarClient) transactions(args Transactions) ![]Transaction {
	return s.client.send_json_rpc[[]Transactions, []Transaction]('stellar.Transactions',
		[args], default_timeout)!
}

// Height of the chain for the connected rpc remote
pub fn (mut s StellarClient) height() !u64 {
	return s.client.send_json_rpc[[]string, u64]('stellar.Height', []string{}, default_timeout)!
}

// Get data related to a stellar account, leave account empty for account data of loaded account
pub fn (mut s StellarClient) account_data(account string) !AccountData {
	return s.client.send_json_rpc[[]string, AccountData]('stellar.AccountData', [
		account,
	], default_timeout)!
}

// Swap tokens from one asset type to the other (for example from tft to xlm)
pub fn (mut s StellarClient) swap(args Swap) !string {
	return s.client.send_json_rpc[[]Swap, string]('stellar.Swap', [args], default_timeout)!
}

// Transfer an amount of TFT from the loaded account to the destination
pub fn (mut s StellarClient) transfer(args Transfer) !string {
	return s.client.send_json_rpc[[]Transfer, string]('stellar.Transfer', [args], default_timeout)!
}

// Get the balance of a specific address, if address is empty the balance of the loaded account will be returned, you can ask the balance of different assets (tft, xlm), default will be xlm
pub fn (mut s StellarClient) balance(args AccountBalance) !string {
	return s.client.send_json_rpc[[]AccountBalance, string]('stellar.Balance', [args],
		default_timeout)!
}

// Bridge tokens of your stellar account to an account on ethereum
pub fn (mut s StellarClient) bridge_to_eth(args BridgeToEth) !string {
	return s.client.send_json_rpc[[]BridgeToEth, string]('stellar.BridgeToEth', [
		args,
	], default_timeout)!
}

// Reinstate later

// // bridge_to_bsc bridge to bsc from stellar
// pub fn (mut s StellarClient) bridge_to_bsc(args BridgeTransfer) ! {
// 	_ := s.client.send_json_rpc[[]BridgeTransfer, string]('stellar.BridgeToBsc', [args], default_timeout)!
// }

// Bridge tokens of your stellar account to an account on tfchain (provide twinid)
pub fn (mut s StellarClient) bridge_to_tfchain(args BridgeToTfchain) !string {
	return s.client.send_json_rpc[[]BridgeToTfchain, string]('stellar.BridgeToTfchain',
		[args], default_timeout)!
}

// Await till a transaction is processed on ethereum bridge that contains a specific memo, that transaction is the result of a bridge from ethereum to the loaded stellar account
pub fn (mut s StellarClient) await_bridged_from_ethereum(args AwaitBridgedFromEthereum) ! {
	_ := s.client.send_json_rpc[[]AwaitBridgedFromEthereum, string]('stellar.AwaitBridgedFromEthereum',
		[args], default_timeout)!
}
