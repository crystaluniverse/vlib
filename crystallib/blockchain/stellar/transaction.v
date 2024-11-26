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
	set_options       ?SetOptions
	create_account    ?TXCreateAccount
	payment           ?PaymentOptions
	change_trust      ?ChangeTrust
	manage_sell_offer ?Offer
	manage_buy_offer  ?Offer
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
	line  AssetType
	limit ?u64
}

pub struct ManageSellOfferPrice {
	n int
	d int
}

type ManageSellOfferAssetType = AssetType | string

pub struct Offer {
pub mut:
	selling    ManageSellOfferAssetType
	buying     ManageSellOfferAssetType
	amount     ?u64
	buy_amount ?u64
	price      ManageSellOfferPrice
	offer_id   u64
}

fn (mut tx TransactionEnvelope) add_change_trust_op(args AddChangeTrustArgs) ! {
	if args.asset_code.len > 12 {
		return error('asset code must be less than 12 bytes')
	}

	asset := Asset{
		asset_code: args.asset_code
		issuer: args.issuer
	}

	mut change_trust_line := AssetType{}
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
pub struct AssetType {
pub mut:
	credit_alphanum4  ?Asset
	credit_alphanum12 ?Asset
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

fn get_offer_asset_type(asset Asset) ManageSellOfferAssetType {
	if asset.asset_code == 'native' {
		return 'native'
	}

	mut asset_type := AssetType{}

	if asset.asset_code.len > 4 {
		asset_type.credit_alphanum12 = asset
	} else {
		asset_type.credit_alphanum4 = asset
	}

	return asset_type
}

@[params]
pub struct MakeOfferOpArgs {
	offer_id u64
	offer    OfferArgs
	sell     bool
	buy      bool
}

fn (mut tx TransactionEnvelope) make_offer_op(args MakeOfferOpArgs) ! {
	if args.sell == args.buy {
		return error('You must either sell or buy at the same time')
	}

	selling_asset_type := get_offer_asset_type(args.offer.selling)
	buying_asset_type := get_offer_asset_type(args.offer.buying)

	mut offer := Offer{
		selling: selling_asset_type
		buying: buying_asset_type
		price: get_offer_price(args.offer.price)
		offer_id: args.offer_id
	}

	mut body := OperationBody{}

	if args.sell {
		offer.amount = args.offer.amount
		body.manage_sell_offer = offer
	} else {
		offer.buy_amount = args.offer.amount
		body.manage_buy_offer = offer
	}

	tx.add_operation(args.offer.source_account, body)!
	tx.tx.fee += 100
}
