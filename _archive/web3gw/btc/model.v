module btc

// configurations to load bitcoin client
@[params]
pub struct Load {
	host string
	user string
	pass string
}

// send amount of token to address, with/without comment
@[params]
pub struct Transfer {
	address    string
	amount     i64
	comment    string // is intended to be used for the purpose of the transaction, keep empty if you don't wat to provide any comment.
	comment_to string // is intended to be used for who the transaction is being sent to.
}

@[params]
pub struct EstimateSmartFee {
	conf_target i64    = 1              // confirmation target in blocks
	mode        string = 'CONSERVATIVE' // defines the different fee estimation modes, should be one of UNSET, ECONOMICAL or CONSERVATIVE
}

pub struct EstimateSmartFeeResult {
	feerate f64
	errors  []string
	blocks  i64
}

@[params]
pub struct GetChainTxStats {
	amount_of_blocks int    // provide statistics for amount_of_blocks blocks, if 0 for all blocks
	block_hash_end   string // provide statistics for amount_of_blocks blocks up until the block with the hash provided in block_hash_end
}

pub struct GetBlockStatsResult {
	avgfee              i64
	avgfeerate          i64
	avgtxsize           i64
	feerate_percentiles []i64
	blockhash           string
	height              i64
	ins                 i64
	maxfee              i64
	maxfeerate          i64
	maxtxsize           i64
	medianfee           i64
	mediantime          i64
	mediantxsize        i64
	minfee              i64
	minfeerate          i64
	mintxsize           i64
	outs                i64
	swtotal_size        i64
	swtotal_weight      i64
	swtxs               i64
	subsidy             i64
	time                i64
	total_out           i64
	total_size          i64
	total_weight        i64
	txs                 i64
	utxo_increase       i64
	utxo_size_inc       i64
}

// GetBlockVerboseTxResult models the data from the getblock command when the
pub struct GetBlockVerboseTxResult {
	hash              string
	confirmations     i64
	strippedsize      int
	size              int
	weight            int
	height            i64
	version           int
	version_hex       string @[json: 'versionHex']
	merkleroot        string
	tx                []TxRawResult
	rawtx             []TxRawResult
	time              i64
	nonce             u32
	bits              string
	difficulty        f64
	previousblockhash string
	nextblockhash     string
}

// TxRawResult models the data from the getrawtransaction command.
pub struct TxRawResult {
	hex           string
	txid          string
	hash          string
	size          int
	vsize         int
	weight        int
	version       u32
	locktime      u32
	vin           []VIn
	vout          []VOut
	blockhash     string
	confirmations u64
	time          i64
	blocktime     i64
}

pub struct VIn {
	coinbase    string
	txid        string
	vout        u32
	script_sig  &ScriptSig @[json: 'scriptSig']
	sequence    u32
	txinwitness []string
}

pub struct ScriptSig {
	asm_ string @[json: 'asm']
	hex  string
}

pub struct VOut {
	value          f64
	n              u32
	script_pub_key ScriptPubKeyResult @[json: 'scriptPubKey']
}

pub struct ScriptPubKeyResult {
	asm_      string @[json: 'asm']
	hex       string
	req_sigs  int    @[json: 'reqSigs']
	type_     string @[json: 'type']
	addresses []string
}

// GetChainTxStatsResult models the data from the getchaintxstats command.
pub struct GetChainTxStatsResult {
	time                      i64
	txcount                   i64
	window_final_block_hash   string
	window_final_block_height int
	window_block_count        int
	window_tx_count           int
	window_interval           int
	txrate                    f64
}

// GetMiningInfoResult models the data from the getmininginfo command.
pub struct GetMiningInfoResult {
	blocks             i64
	currentblocksize   u64
	currentblockweight u64
	currentblocktx     u64
	difficulty         f64
	errors             string
	generate           bool
	genproclimit       int
	hashespersec       f64
	networkhashps      f64
	pooledtx           u64
	testnet            bool
}

// GetNodeAddressesResult models the data returned from the getnodeaddresses command.
pub struct GetNodeAddressesResult {
	// Timestamp in seconds since epoch (Jan 1 1970 GMT) keeping track of when the node was last seen
	time     i64
	services u64
	address  string
	port     u16
}

// GetPeerInfoResult models the data returned from the getpeerinfo command.
pub struct GetPeerInfoResult {
	id             int
	addr           string
	addrlocal      string
	services       string
	relaytxes      bool
	lastsend       i64
	lastrecv       i64
	bytessent      u64
	bytesrecv      u64
	conntime       i64
	timeoffset     i64
	pingtime       f64
	pingwait       f64
	version        u32
	subver         string
	inbound        bool
	startingheight int
	currentheight  int
	banscore       int
	feefilter      i64
	syncnode       bool
}

pub struct Transaction {
	msg_tx          MsgTx  // Underlying MsgTx
	tx_hash         []byte // Cached transaction hash
	tx_hash_witness []byte // Cached transaction witness hash
	tx_has_witness  bool   // If the transaction has witness data
	tx_index        int    // Position within a block or TxIndexUnknown
}

pub struct MsgTx {
	version   int
	tx_in     []TxIn
	tx_out    []TxOut
	lock_time u32
}

pub struct TxIn {
	previous_out_point OutPoint
	signature_script   []byte
	witness            [][]byte
	sequence           u32
}

pub struct OutPoint {
	hash  []byte
	index u32
}

pub struct TxOut {
	value     i64
	pk_script []byte
}
