module stellar

struct TimeBounds {
    min_time u64
    max_time u64
}

struct Condition {
    time TimeBounds
}

struct Signer {
    key    string
    weight int
}

struct SetOptions {
    inflation_dest string
    clear_flags    ?int
    set_flags      ?int
    master_weight  ?int
    low_threshold  ?int
    med_threshold  ?int
    high_threshold ?int
    home_domain    ?string
    signer         ?Signer
}

// a placeholder.
struct PaymentOptions {}

struct OperationBody {
    set_options ?SetOptions
    payment 	?PaymentOptions
}

struct TransactionOperation {
    source_account ?string
    body           OperationBody
}

struct Transaction {
    source_account string
    fee            int = 100
    seq_num        u64
    cond           ?Condition
    memo           string = "none"
    operations     []TransactionOperation
    ext            string = "v0"
}

struct TransactionEnvelope {
    tx         Transaction
    // signatures []string TODO: Check the valid type.
}


struct TransactionArgs {
	operation
}



fn (tx Transaction) add_operation(args TransactionArgs) !  {
	
}

fn (tx Transaction) add_signer(args TransactionArgs) !  {
	
}


fn encode_transaction(tx Transaction) !string {
	return json.encode(tx)!
}