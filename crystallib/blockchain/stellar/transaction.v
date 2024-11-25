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

@[noinit]
pub struct OperationBody {
pub mut:
	set_options    ?SetOptions
	create_account ?TXCreateAccount
	payment        ?PaymentOptions
	change_trust   ?ChangeTrust
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

pub struct ChangeTrust {
pub mut:
	line  ChangeTrustLine
	limit ?u64
}

fn (mut tx TransactionEnvelope) add_change_trust_op(args AddChangeTrustArgs) ! {
	if args.asset_code.len > 12 {
		return error('asset code must be less than 12 bytes')
	}

	asset := Asset{
		asset_code: args.asset_code
		issuer: args.issuer
	}

	mut change_trust_line := ChangeTrustLine{}
	if args.asset_code.len <= 4 {
		change_trust_line.credit_alphanum4 = asset
	} else {
		change_trust_line.credit_alphanum12 = asset
	}

	body := OperationBody{
		change_trust: ChangeTrust{
			line: change_trust_line
			limit: args.limit
		}
	}

	tx.add_operation(args.source_account, body)!
	tx.tx.fee += 100
}

@[noinit]
pub struct ChangeTrustLine {
pub mut:
	credit_alphanum4  ?Asset
	credit_alphanum12 ?Asset
}

pub enum AssetType {
	credit_alphanum4
	credit_alphanum12
}

pub struct Asset {
pub mut:
	asset_code string
	issuer     string
}

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

// TODO: rewrite operations checking
fn (mut tx TransactionEnvelope) add_operation(source_account ?string, op OperationBody) ! {
	mut ops := 0

	$for field in op.fields {
		if op.$(field.name) != none {
			ops += 1
		}
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

// Struct for the "create_account" request
@[params]
pub struct TXCreateAccount {
pub mut:
	destination      string @[required] // The public key of the account to create
	starting_balance u64    @[required]    // Use f64 for the raw balance (in this case, 100.0)
}

fn (mut tx TransactionEnvelope) add_create_account_op(source_account ?string, args TXCreateAccount) ! {
	body := OperationBody{
		create_account: args
	}

	tx.add_operation(source_account, body)!
	tx.tx.fee += 100
}
