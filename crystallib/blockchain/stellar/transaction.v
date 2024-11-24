module stellar

import json
import os

struct TimeBounds {
	min_time u64
	max_time u64
}

struct Condition {
	time TimeBounds
}

struct TXSigner {
pub:
	key    string
	weight int = 1
}

struct SetOptions {
	inflation_dest ?string
	clear_flags    ?int
	set_flags      ?int
	master_weight  ?int
	low_threshold  ?int
	med_threshold  ?int
	high_threshold ?int
	home_domain    ?string
	signer         ?TXSigner
}

// a placeholder.
struct PaymentOptions {
	to string
}

struct OperationBody {
	set_options ?SetOptions
	payment     ?PaymentOptions
}

struct TransactionOperation {
	source_account ?string
	body           OperationBody
}

struct Transaction {
pub mut:
	source_account string
	fee            int = 100
	seq_num        u64
	cond           Condition
	memo           string = 'none'
	operations     []TransactionOperation
	ext            string = 'v0'
}

// @[params]
// struct NewTransactionArgs{
//     source_account string @[required]
//     fee
// }

fn (mut c StellarClient) new_transaction_envelope(source_account_address string) !TransactionEnvelope {
	hcl := new_horizon_client(c.network)!
	account := hcl.get_account(source_account_address)!

	sequence_number := account.sequence.u64() + 1

	return TransactionEnvelope{
		tx: Transaction{
			source_account: source_account_address
			seq_num: sequence_number
		}
	}
}

struct TransactionEnvelope {
mut:
	tx         Transaction
	signatures []string
}

// struct TransactionArgs {
// 	operation
// }

fn (mut tx TransactionEnvelope) add_operation(source_account ?string, op OperationBody) ! {
	mut ops := 0
	if _ := op.set_options {
		ops += 1
	}

	if op.payment != none {
		ops += 1
	}

	if ops != 1 {
		return error('only one operation type must be added per operation, found ${ops}')
	}

	tx.tx.operations << TransactionOperation{
		source_account: source_account
		body: op
	}
}

@[params]
struct TXAddSignerArgs {
	source_account ?string
	signer         TXSigner
}

fn (mut tx TransactionEnvelope) add_signer(args TXAddSignerArgs) ! {
	body := OperationBody{
		set_options: SetOptions{
			signer: args.signer
		}
	}

	tx.add_operation(args.source_account, body)!
}

@[params]
struct TXAddSetOptionsOperationArgs {
	source_account ?string
	set_options    SetOptions
}

fn (mut tx TransactionEnvelope) add_set_options_op(args TXAddSetOptionsOperationArgs) ! {
	body := OperationBody{
		set_options: args.set_options
	}

	tx.add_operation(args.source_account, body)!
}

fn (tx TransactionEnvelope) encode() !string {
	json_encoding := json.encode({
		'tx': tx
	})

	cmd := "echo '${json_encoding}' | stellar xdr encode --type TransactionEnvelope"
	result := os.execute(cmd)
	if result.exit_code != 0 {
		return error('failed to encode tx: ${result.output}')
	}

	return result.output.trim_space()
}
