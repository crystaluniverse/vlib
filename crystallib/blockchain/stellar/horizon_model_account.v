module stellar

pub struct Links {
pub mut:
	self         Link
	transactions Link
	operations   Link
	payments     Link
	effects      Link
	offers       Link
	trades       Link
	data         Link
}

pub struct Link {
pub mut:
	href      string
	templated bool
}

pub struct Thresholds {
pub mut:
	low_threshold  int
	med_threshold  int
	high_threshold int
}

pub struct Flags {
pub mut:
	auth_required         bool
	auth_revocable        bool
	auth_immutable        bool
	auth_clawback_enabled bool
}

pub struct Balance {
pub mut:
	balance                               string
	limit                                 string
	buying_liabilities                    string
	selling_liabilities                   string
	last_modified_ledger                  int
	is_authorized                         bool
	is_authorized_to_maintain_liabilities bool
	asset_type                            string
	asset_code                            string
	asset_issuer                          string
}

pub struct Signer {
pub mut:
	weight int
	key    string
	@type  string
}

@[heap]
pub struct StellarAccount {
pub mut:
	links                Links
	id                   string
	account_id           string
	sequence             string
	sequence_ledger      int
	sequence_time        string
	subentry_count       int
	last_modified_ledger int
	last_modified_time   string
	thresholds           Thresholds
	flags                Flags
	balances             []Balance
	signers              []Signer
	data                 map[string]string
	num_sponsoring       int
	num_sponsored        int
	paging_token         string
}

pub struct TransactionInfo {
pub:
	links    RootLinks @[json: '_links']
	embedded Embedded  @[json: '_embedded']
}

pub struct RootLinks {
pub:
	self Link
	next Link
	prev Link
}

pub struct Embedded {
pub:
	records []Record
}

pub struct Record {
pub:
	links                   RecordLinks   @[json: '_links']
	id                      string
	paging_token            string
	successful              bool
	hash                    string
	ledger                  int
	created_at              string
	source_account          string
	source_account_sequence string
	fee_account             string
	fee_charged             string
	max_fee                 string
	operation_count         int
	envelope_xdr            string
	result_xdr              string
	fee_meta_xdr            string
	memo_type               string
	signatures              []string
	preconditions           Preconditions
}

pub struct RecordLinks {
pub:
	self        Link
	account     Link
	ledger      Link
	operations  Link
	effects     Link
	precedes    Link
	succeeds    Link
	transaction Link
}

pub struct Preconditions {
pub:
	timebounds PreConditionTimeBounds
}

pub struct PreConditionTimeBounds {
pub:
	min_time string
}
