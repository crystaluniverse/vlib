module stellar

import x.json2

pub struct TimeBounds {
pub:
	min_time u64
	max_time u64
}

pub struct Condition {
pub:
	time TimeBounds
}

@[params]
pub struct TXSigner {
pub:
	key    string
	weight int = 1
}

pub struct SetOptions {
pub mut:
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
pub struct PaymentOptions {
pub mut:
	to string
}

pub struct OperationBody {
pub mut:
	set_options ?SetOptions
	payment     ?PaymentOptions
}

pub struct TransactionOperation {
pub mut:
	source_account ?string
	body           OperationBody
}

pub struct Transaction {
pub mut:
	source_account string
	fee            int
	seq_num        u64
	cond           Condition
	memo           string = 'none'
	operations     []TransactionOperation
	ext            string = 'v0'
}

// @[params]
pub // struct NewTransactionArgs{
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

pub struct TransactionEnvelope {
pub mut:
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
pub struct TXAddSignerArgs {
pub:
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
	tx.tx.fee += 100
}

@[params]
pub struct TXAddSetOptionsOperationArgs {
	source_account ?string
	set_options    SetOptions
}

fn (mut tx TransactionEnvelope) add_set_options_op(args TXAddSetOptionsOperationArgs) ! {
	body := OperationBody{
		set_options: args.set_options
	}

	tx.add_operation(args.source_account, body)!
	tx.tx.fee += 100
}

fn (tx TransactionEnvelope) xdr() !string {
	json_encoding := json2.encode({
		'tx': tx
	})

	return encode_tx_to_xdr(json_encoding)!
}
