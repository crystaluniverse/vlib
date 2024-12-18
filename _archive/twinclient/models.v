module twinclient

import freeflowuniverse.crystallib.clients.redisclient
import net.websocket as ws
import net.http

pub struct WSTwinClient {
pub mut:
	ws       ws.Client
	channels map[string]chan Message
}

pub enum TwinClientTypeEnum {
	http
	rmb
	ws
}

pub struct TwinClient {
pub mut:
	transport ITwinTransport
}

pub struct HttpTwinClient {
pub mut:
	url    string
	method http.Method
	header http.Header
	data   string
}

pub struct RmbTwinClient {
pub mut:
	client  redisclient.Redis
	message Message
}

pub struct Message {
pub mut:
	event      string // Used for web socket events
	version    int    @[json: ver] // protocol version, used for update
	id         string @[json: uid] // unique identifier set by server
	command    string @[json: cmd] // command to request in dot notation
	expiration int    @[json: exp] // expiration in seconds, based on epoch
	retry      int    @[json: try] // amount of retry if remote is unreachable
	data       string @[json: dat] // binary payload to send to remote, base64 encoded
	twin_src   int    @[json: src] // twinid source, will be set by server
	twin_dst   []int  @[json: dst] // twinid of destination, can be more than one
	retqueue   string @[json: ret] // return queue name where to send reply
	schema     string @[json: shm] // schema to define payload, later could enforce payload
	epoch      i64    @[json: now] // unix timestamp when request were created
	err        string @[json: err] // optional error message if any
}

struct Factory {
mut:
	clients map[string]WSTwinClient
}

pub struct InvokeRequest {
mut:
	function string
	args     string
}

pub interface ITwinTransport {
mut:
	send(functionPath string, args string) !Message
	// wait(id string, timeout u32)! CustomResponse
}

pub type TwinClientType = HttpTwinClient | RmbTwinClient | WSTwinClient
pub type RawMessage = ws.Message

@[params]
pub struct SingleDelete {
pub:
	name            string @[required]
	deployment_name string @[required]
}

pub struct Disk {
pub:
	name       string @[required]
	size       u32    @[required]
	mountpoint string @[required]
}

@[params]
pub struct QsfsDisk {
pub:
	qsfs_zdbs_name  string @[required]
	name            string @[required]
	prefix          string @[required]
	encryption_key  string @[required]
	cache           u32
	minimal_shards  u32
	expected_shards u32
	mountpoint      string @[required]
}

pub struct Network {
pub:
	ip_range   string @[required]
	name       string @[required]
	add_access bool   @[json: 'addAccess']
}

pub struct Machine {
pub:
	name        string @[required]
	node_id     u32    @[required]
	disks       []Disk
	qsfs_disks  []QsfsDisk
	public_ip   bool   @[required]
	planetary   bool   @[required]
	cpu         u32    @[required]
	memory      u64    @[required]
	rootfs_size u64    @[required]
	flist       string @[required]
	entrypoint  string @[required]
	env         Env
}

@[params]
pub struct AddMachine {
pub:
	name        string @[required]
	node_id     u32    @[required]
	disks       []Disk
	qsfs_disks  []QsfsDisk
	public_ip   bool   @[required]
	planetary   bool   @[required]
	cpu         u32    @[required]
	memory      u64    @[required]
	rootfs_size u64    @[required]
	flist       string @[required]
	entrypoint  string @[required]
	env         Env
}

@[params]
pub struct MachinesModel {
pub:
	name        string    @[required]
	network     Network   @[required]
	machines    []Machine @[required]
	metadata    string
	description string
}

pub struct KubernetesNode {
pub:
	name        string @[required]
	node_id     u32    @[required]
	cpu         u32    @[required]
	memory      u64    @[required]
	rootfs_size u32    @[required]
	disk_size   u32    @[required]
	qsfs_disks  []QsfsDisk
	public_ip   bool @[required]
	planetary   bool @[required]
}

@[params]
pub struct AddKubernetesNode {
pub:
	deployment_name string @[required]
	name            string @[required]
	node_id         u32    @[required]
	cpu             u32    @[required]
	memory          u64    @[required]
	rootfs_size     u32    @[required]
	disk_size       u32    @[required]
	qsfs_disks      []QsfsDisk
	public_ip       bool @[required]
	planetary       bool @[required]
}

@[params]
pub struct K8SModel {
pub:
	name        string           @[required]
	secret      string           @[required]
	network     Network          @[required]
	masters     []KubernetesNode @[required]
	workers     []KubernetesNode
	metadata    string
	description string
	ssh_key     string @[required]
}

pub struct ZDB {
pub:
	name             string @[required]
	node_id          u32    @[required]
	mode             string @[required]
	disk_size        u32    @[required]
	public_namespace bool   @[json: 'publicNamespace'; required]
	password         string @[required]
}

@[params]
pub struct AddZDB {
pub:
	deployment_name  string @[required]
	name             string @[required]
	node_id          u32    @[required]
	mode             string @[required]
	disk_size        u32    @[required]
	public_namespace bool   @[json: 'publicNamespace'; required]
	password         string @[required]
}

@[params]
pub struct ZDBs {
pub:
	name        string @[required]
	zdbs        []ZDB  @[required]
	metadata    string
	description string
}

@[params]
pub struct QSFSZDBs {
pub:
	name        string @[required]
	count       u32    @[required]
	node_ids    []u32  @[required]
	disk_size   u64    @[required]
	password    string @[required]
	metadata    string
	description string
}

@[params]
pub struct GatewayFQDN {
pub:
	name            string   @[required]
	node_id         u32      @[required]
	fqdn            string   @[required]
	tls_passthrough bool     @[required]
	backends        []string @[required]
}

@[params]
pub struct GatewayName {
pub:
	name            string   @[required]
	node_id         u32      @[required]
	tls_passthrough bool     @[required]
	backends        []string @[required]
}

@[params]
pub struct NodeContractCreate {
pub:
	node_id   u32    @[required]
	hash      string @[required]
	data      string @[required]
	public_ip u32    @[required]
}

@[params]
pub struct NodeContractUpdate {
pub:
	id   u64    @[required]
	hash string @[required]
	data string @[required]
}

@[params]
pub struct ContractIdByNodeIdAndHash {
pub mut:
	node_id u32    @[required]
	hash    string @[required]
}

pub struct Contract {
pub:
	version       u32
	contract_id   u64           @[json: 'contractId']
	twin_id       u32           @[json: 'twinId']
	contract_type ContractTypes @[json: 'contractType']
	state         ContractState
}

pub struct SimpleContract {
pub:
	contract_id u64 @[json: 'contractId']
}

struct SimpleDeleteContract {
pub:
	contract_id u64
}

struct ContractTypes {
pub:
	node_contract NodeContract @[json: 'nodeContract']
	name_contract NameModel    @[json: 'NameModel']
}

pub struct ListContracts {
pub:
	node_contracts []SimpleContract @[json: 'nodeContracts']
	name_contracts []SimpleContract @[json: 'NameModels']
}

struct NodeContract {
pub:
	node_id         u32        @[json: 'nodeId']
	deployment_data string     @[json: 'deploymentData']
	deployment_hash string     @[json: 'deploymentHash']
	public_ips      u32        @[json: 'publicIps']
	public_ips_list []PublicIP @[json: 'publicIpsList']
}

struct NameModel {
pub:
	name string
}

struct ContractState {
pub:
	created string
	deleted string
}

struct PublicIP {
pub:
	id          string
	ip          string
	gateway     string
	contract_id u64 @[json: 'contractId']
}

pub struct ContractResponse {
pub:
	created []Contract
	updated []Contract
	deleted []SimpleDeleteContract
}

pub struct DeployResponse {
pub:
	contracts        ContractResponse
	wireguard_config string
}

pub struct Env {
pub:
	ssh_key string @[json: 'SSH_KEY']
}

@[params]
pub struct StellarWallet {
pub mut:
	name    string
	address string
	secret  string
}

pub struct BalanceResult {
pub:
	free        f64
	reserved    f64
	misc_frozen f64 @[json: 'miscFrozen']
	fee_frozen  f64 @[json: 'feeFrozen']
}

@[params]
pub struct BalanceTransfer {
pub:
	address string @[required]
	amount  f64    @[required]
}

pub struct StellarBalance {
pub:
	asset  string
	amount string
}

@[params]
pub struct StellarTransfer {
pub:
	from_name      string @[json: 'name'; required]
	target_address string @[required]
	amount         f64    @[required]
	asset          string = 'TFT'
	memo           string
}

pub struct TwinModel {
pub:
	version    u32
	id         u32
	account_id string
	ip         string
	entities   []EntityProof
}

struct EntityProof {
	entity_id u32
	signature string
}

@[params]
pub struct PagePayload {
pub:
	page       u32 = 1
	max_result u32 = 50 @[json: 'maxResult']
}

@[params]
pub struct FilterOptions {
pub:
	cru            u32    @[omitempty]
	mru            u32    @[omitempty]
	sru            u32    @[omitempty]
	hru            u32    @[omitempty]
	public_ips     bool   @[json: 'publicIPs'; omitempty]
	access_node_v4 bool   @[json: 'accessNodeV4'; omitempty]
	access_node_v6 bool   @[json: 'accessNodeV6'; omitempty]
	gateway        bool   @[omitempty]
	farm_id        u32    @[json: 'farmId'; omitempty]
	farm_name      string @[json: 'farmName']
	available_for  u32    @[json: 'availableFor']
	country        string
	city           string
}

pub struct Farm {
pub:
	name              string
	farm_id           u32 @[json: 'farmId']
	twin_id           u32 @[json: 'twinId']
	version           u32
	pricing_policy_id u32        @[json: 'pricingPolicyId']
	stellar_address   string     @[json: 'stellarAddress']
	public_ips        []PublicIP @[json: 'publicIPs']
}

pub struct Node {
pub:
	version            u32
	id                 string
	node_id            u32 @[json: 'nodeId']
	farm_id            u32 @[json: 'farmId']
	twin_id            u32 @[json: 'twinId']
	country            string
	city               string
	grid_version       u32 @[json: 'gridVersion']
	uptime             u64
	created            u64
	farming_policy_id  u32    @[json: 'farmingPolicyId']
	updated_at         string @[json: 'updatedAt']
	cru                string
	mru                string
	sru                string
	hru                string
	public_config      PublicConfig
	status             string
	certification_type string @[json: 'certificationType']
}

struct PublicConfig {
	domain string
	gw4    string
	gw6    string
	ipv4   string
	ipv6   string
}

pub struct FreeResources {
pub:
	cru   u32
	mru   u64
	hru   u64
	sru   u64
	ipv4u u32
}

pub struct AddressModel {
mut:
	address string
}

pub struct TFChainPayModel {
pub:
	name           string
	target_address string
	amount         f64
}

pub struct AlgorandPayModel {
pub:
	name         string
	address_dest string
	amount       f64
	description  string
}

pub struct StellarPayModel {
pub:
	name         string
	address_dest string
	amount       f64
	asset        string
	description  string
}

pub struct AlgorandPayResponseModel {
pub:
	txid string @[json: 'txId']
}

pub struct AlgorandAccountAddressModel {
pub:
	address string
}

pub struct AlgorandAccountMnemonicsModel {
pub:
	mnemonics string
}

pub struct BlockChainSignResponseModel {
pub:
	message string
}

pub struct NameMnemonicModel {
pub:
	name     string
	mnemonic string
}

pub struct NameSecretModel {
pub:
	name   string
	secret string
}

pub struct NameIPModel {
pub:
	name string
	ip   string
}

pub struct BlockChainSignModel {
pub:
	name    string
	content string
}

pub struct AssetsModel {
pub:
	amount f64
	asset  string
}

pub struct BlockChainAssetsModel {
pub:
	name            string
	public_key      string
	blockchain_type string
	assets          []AssetsModel
}

pub struct BlockChainCreateModel {
pub mut:
	name            string
	public_key      string
	mnemonic        string
	blockchain_type string
	twin_id         string
	ip              string
}

pub struct BlockChainCreateResponseModel {
pub mut:
	name            string
	public_key      string
	mnemonic        string
	blockchain_type string
	twin_id         string @[json: 'twinId']
}

pub struct BlockChainModel {
pub:
	name            string
	public_key      string
	blockchain_type string
}

pub struct NameAddressMnemonicModel {
pub mut:
	name     string
	address  string
	mnemonic string
}

pub struct BlockchainSignModel {
pub:
	name    string
	content string
}

pub struct BlockchainSignNoNameModel {
pub:
	content string
}

pub struct StellarWalletVerifyModel {
pub:
	public_key     string
	content        string
	signed_content string
}

pub struct BlockchainInitModel {
pub:
	name            string
	blockchain_type string
	secret          string
}

pub struct BlockchainCreateResultModel {
pub:
	mnemonic string
	twin_id  string
}

pub struct BlockchainListModel {
pub:
	blockchain_type string
}

pub struct BlockchainPayNoNameModel {
pub:
	blockchain_type_dest string
	description          string
	address_dest         string
	amount               f64
	asset                string
}

pub struct Zos {
mut:
	client &TwinClient
}

pub struct SignatureRequest {
pub mut:
	twin_id  u32
	required bool
	weight   int
}

pub struct Signature {
pub mut:
	twin_id   u32
	signature string
}

pub struct SignatureRequirement {
pub mut:
	requests        []SignatureRequest
	weight_required int
	signatures      []Signature
}

pub struct Deployment {
pub mut:
	version               int
	twin_id               u32
	contract_id           u64
	expiration            i64
	metadata              string
	description           string
	workloads             []Workload
	signature_requirement SignatureRequirement
}

pub struct ResultStates {
pub:
	error   string = 'error'
	ok      string = 'ok'
	deleted string = 'deleted'
}

pub struct DeploymentResult {
pub mut:
	created i64
	state   string
	error   string
	data    string @[raw]
}

pub struct Workload {
pub mut:
	version     int
	name        string
	type_       string @[json: 'type']
	data        string @[raw]
	metadata    string
	description string
	result      DeploymentResult
}

pub enum BlockChainType {
	algorand
	stellar
	tfchain
}

pub struct ZOSGetDeployment {
pub mut:
	node_id u32 @[json: 'nodeId']
}

struct ZOSNodeStatisticsResources {
	cru   u32
	sru   u32
	hru   u32
	mru   u32
	ipv4u u32
}

pub struct ZOSNodeStatisticsResponse {
pub mut:
	total ZOSNodeStatisticsResources
	used  ZOSNodeStatisticsResources
}
