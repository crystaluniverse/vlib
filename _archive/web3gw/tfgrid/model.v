module tfgrid

@[params]
pub struct Load {
	mnemonic string // secret mnemonic
	network  string // grid network [dev, qa, test, main]
}

@[params]
pub struct DeployVM {
	VMConfiguration
pub mut:
	add_wireguard_access bool
	gateway              bool
}

pub struct VMDeployment {
	VMConfiguration
pub mut:
	network          string
	wireguard_config string
	gateway_name     string
}

pub struct VMConfiguration {
pub mut:
	name        string @[required] // machine name
	node_id     u32 // node id to deploy on, if 0, a random eligible node will be selected
	farm_id     u32 // farm id to deploy on, if 0, a random eligible farm will be selected
	flist       string = 'https://hub.grid.tf/tf-official-apps/base:latest.flist' // flist of the machine
	entrypoint  string = '/sbin/zinit init' // entry point for the machine
	public_ip   bool // if true, a public ipv4 will be added to the node
	public_ip6  bool // if true, a public ipv6 will be added to the node
	planetary   bool = true // if true, a planetary ip will be added to the node
	cpu         u32  = 1    // number of vcpu cores
	memory      u64  = 1024 // memory of the machine in MBs
	rootfs_size u64               // root file system size in MBs
	zlogs       []Zlog            // zlogs configs
	disks       []Disk            // disks configs
	qsfss       []QSFS            // qsfss configs
	env_vars    map[string]string // env vars to attach to the machine
	description string            // machine description
	// computed
	computed_ip4 string // public ipv4 attached to this machine, if any
	computed_ip6 string // public ipv6 attached to this machine, if any
	wireguard_ip string // private wireguard ip of this machine
	planetary_ip string // planetary ip attached to this machine, if any
}

pub struct Disk {
pub:
	size        u32    @[required] // disk size in GBs
	mountpoint  string @[required] // mountpoint of the disk on the machine
	description string // disk description
	// computed
	name string // disk name
}

pub struct QSFS {
pub:
	mountpoint            string @[required] // mountpoint of the qsfs on the machine
	encryption_key        string @[required] // 64 long hex encoded encryption key (e.g. 0000000000000000000000000000000000000000000000000000000000000000).
	cache                 u32    @[required] // The size of the fuse mountpoint on the node in MBs (holds qsfs local data before pushing).
	minimal_shards        u32    @[required] // The minimum amount of shards which are needed to recover the original data.
	expected_shards       u32    @[required] // The amount of shards which are generated when the data is encoded. Essentially, this is the amount of shards which is needed to be able to recover the data, and some disposable shards which could be lost. The amount of disposable shards can be calculated as expected_shards - minimal_shards.
	redundant_groups      u32    @[required] // The amount of groups which one should be able to loose while still being able to recover the original data.
	redundant_nodes       u32    @[required] // The amount of nodes that can be lost in every group while still being able to recover the original data.
	encryption_algorithm  string = 'AES'    // configuration to use for the encryption stage. Currently only AES is supported.
	compression_algorithm string = 'snappy' // configuration to use for the compression stage. Currently only snappy is supported.
	metadata              Metadata @[required] // metadata configs
	description           string // qsfs description

	max_zdb_data_dir_size u32     @[required] // Maximum size of the data dir in MiB, if this is set and the sum of the file sizes in the data dir gets higher than this value, the least used, already encoded file will be removed.
	groups                []Group @[required] // groups configs
	// computed
	name             string // qsfs name
	metrics_endpoint string // metrics endpoint for the qsfs
}

pub struct Metadata {
pub:
	type_                string = 'zdb' @[json: 'type']         // configuration for the metadata store to use, currently only ZDB is supported.
	prefix               string @[required]     // Data stored on the remote metadata is prefixed with.
	encryption_algorithm string = 'AES' // configuration to use for the encryption stage. Currently only AES is supported.
	encryption_key       string @[required] // 64 long hex encoded encryption key (e.g. 0000000000000000000000000000000000000000000000000000000000000000).
	backends             []Backend // backends configs
}

pub struct Group {
pub:
	backends []Backend
}

pub struct Backend {
pub:
	address   string @[required] // Address of backend ZDB (e.g. [300:a582:c60c:df75:f6da:8a92:d5ed:71ad]:9900 or 60.60.60.60:9900).
	namespace string @[required] // ZDB namespace.
	password  string @[required] // Namespace password.
}

pub struct Zlog {
pub:
	output string // Url of the remote location receiving logs. URLs should use one of `redis, ws, wss` schema. e.g. wss://example_ip.com:9000
}

@[params]
pub struct NetworkDeployment {
pub mut:
	name        string               // identifier for the network deployment, must be unique
	metadata    string               // metadata for the model
	description string               // description of the model
	network     NetworkConfiguration // network configuration
	vms         []VMConfiguration    // VM configurations
}

@[params]
pub struct NetworkConfiguration {
pub mut:
	name                 string // network name
	add_wireguard_access bool   // if true, a wireguard access point will be added to the network
	ip_range             string = '10.1.0.0/16' // network ip range, must have a subnet mask of 16
	// computed
	wireguard_config string // wireguard configuration, if any
}

@[params]
pub struct AddVMToNetworkDeployment {
	VMConfiguration
pub mut:
	network string // unique id of the networkdeployment where the new vm should be added to
}

@[params]
pub struct RemoveVMFromNetworkDeployment {
pub mut:
	vm      string // unique id of the vm that should be removed from the network deployment
	network string // unique id of the networkdeployment where the new vm should be removed from
}

@[params]
pub struct K8sCluster {
pub mut:
	name          string    // cluster name
	token         string    // cluster token, workers must have this token to join the cluster
	ssh_key       string    // public ssh key to access the instance in a later stage
	master        K8sNode   // master config
	workers       []K8sNode // workers configs
	add_wg_access bool      // if true, adds a wireguard access point to the network
}

pub struct K8sNode {
pub mut:
	name       string // name of the cluster node
	node_id    u32    // node id to deploy on, if 0, a random eligible node will be selected
	farm_id    u32    // farm id to deploy on, if 0, a random eligible farm will be selected
	public_ip  bool   // if true, a public ipv4 will be added to the node
	public_ip6 bool   // if true, a public ipv6 will be added to the node
	planetary  bool   = true // if true, a yggdrasil ip will be added to the node
	flist      string = 'https://hub.grid.tf/tf-official-apps/threefoldtech-k3s-latest.flist' // flist for kubernetes
	cpu        u32 // number of vcpu cores.
	memory     u32 // node memory in MBs
	disk_size  u32 = 10 // size of disk mounted on the node in GB, monted in /mydisk
	// computed
	computed_ip4 string // public ipv4 attached to this node, if any
	computed_ip6 string // public ipv6 attached to this node, if any
	wg_ip        string // wireguard private ip of this node
	planetary_ip string // planetary ip attached to this node, if any
}

@[params]
pub struct AddWorkerToK8sCluster {
pub mut:
	worker       K8sNode // the new worker to add to the cluster
	cluster_name string  // the name of the k8s cluster to add the new worker to
}

@[params]
pub struct RemoveWorkerFromK8sCluster {
pub mut:
	cluster_name string // the name of the k8s cluster to remove the worker from
	worker_name  string // the name of the worker that should be removed from the k8s cluster
}

@[params]
pub struct ZDBDeployment {
pub mut:
	node_id     u32    // node id of the ZDB
	name        string // zdb name, must be unique
	password    string // zdb password
	public      bool   // Makes it read-only if password is set, writable if no password set.
	size        u32    // size of the zdb in GB
	description string // zdb description
	mode        string // Mode of the ZDB, `user` or `seq`. `user` is the default mode where a user can SET their own keys, like any key-value store. All keys are kept in memory. in `seq` mode, keys are sequential and autoincremented.
	// computed
	namespace string   // namespace of the zdb
	port      u32      // port of the zdb
	ips       []string // Computed IPs of the ZDB. Two IPs are returned: a public IPv6, and a YggIP, in this order
}

@[params]
pub struct GatewayName {
pub mut:
	name            string   @[json: 'name']            // identifier for the gateway, must be unique
	node_id         u32      @[json: 'node_id']         // node to deploy the gateway workload on, if 0, a random elibile node will be selected
	tls_passthrough bool     @[json: 'tls_passthrough'] // True to enable TLS encryption
	backends        []string @[json: 'backends']        // The backend that the gateway will point to
	// computed
	fqdn             string // the full domain name for this instance
	name_contract_id u32    // name contract id
	contract_id      u32    // contract id for the gateway
}

@[params]
pub struct GatewayFQDN {
pub mut:
	name            string   @[json: 'name']            // name of the instance
	node_id         u32      @[json: 'node_id']         // node id that the instance was deployed on
	tls_passthrough bool     @[json: 'tls_passthrough'] // whether or not tls was enables
	backends        []string @[json: 'backends']        // backends that this gateway is pointing to
	fqdn            string   @[json: 'fqdn']            // fully qualified domain name pointing to this gatewat
	// computed
	contract_id u32 // contract id for the gateway
}

pub struct Limit {
pub:
	size      u64
	page      u64
	randomize bool
}

@[params]
pub struct FindNodes {
pub mut:
	filters    NodeFilter
	pagination Limit
}

@[params]
pub struct FindFarms {
pub mut:
	filters    FarmFilter
	pagination Limit
}

@[params]
pub struct FindContracts {
pub mut:
	filters    ContractFilter
	pagination Limit
}

@[params]
pub struct FindTwins {
pub mut:
	filters    TwinFilter
	pagination Limit
}

@[params]
pub struct GetStatistics {
pub mut:
	status ?string @[json: 'Status']
}

// available options for filtering nodes
@[params]
pub struct NodeFilter {
pub mut:
	status             ?string @[json: 'Status']
	free_mru           ?u64    @[json: 'FreeMru']
	free_hru           ?u64    @[json: 'FreeHru']
	free_sru           ?u64    @[json: 'FreeSru']
	total_mru          ?u64    @[json: 'TotalMru']
	total_hru          ?u64    @[json: 'TotalHru']
	total_sru          ?u64    @[json: 'TotalSru']
	total_cru          ?u64    @[json: 'TotalCru']
	country            ?string @[json: 'Country']
	country_contains   ?string @[json: 'CountryContains']
	city               ?string @[json: 'City']
	city_contains      ?string @[json: 'CityContains']
	farm_name          ?string @[json: 'FarmName']
	farm_name_contains ?string @[json: 'FarmNameContains']
	farm_ids           ?[]u64  @[json: 'FarmIds']
	free_ips           ?u64    @[json: 'FreeIps']
	ipv4               ?bool   @[json: 'IPv4']
	ipv6               ?bool   @[json: 'IPv6']
	domain             ?bool   @[json: 'Domain']
	dedicated          ?bool   @[json: 'Dedicated']
	rentable           ?bool   @[json: 'Rentable']
	rented             ?bool   @[json: 'Rented']
	healthy            ?bool   @[json: 'healthy']
	rented_by          ?u64    @[json: 'RentedBy']
	available_for      ?u64    @[json: 'AvailableFor']
	node_id            ?u64    @[json: 'NodeID']
	twin_id            ?u64    @[json: 'TwinID']
}

// available options for filtering farms
pub struct FarmFilter {
pub mut:
	free_ips           ?u64    @[json: 'FreeIPs']
	total_ips          ?u64    @[json: 'TotalIPs']
	stellar_address    ?string @[json: 'StellarAddress']
	pricing_policy_id  ?u64    @[json: 'PricingPolicyId']
	farm_id            ?u64    @[json: 'FarmId']
	twin_id            ?u64    @[json: 'TwinId']
	name               ?string @[json: 'Name']
	name_contains      ?string @[json: 'NameContains']
	certification_type ?string @[json: 'CertificationType']
	dedicated          ?bool   @[json: 'Dedicated']
}

// available options for filtering twins
pub struct TwinFilter {
pub mut:
	twin_id    ?u64    @[json: 'TwinID']
	account_id ?string @[json: 'AccountID']
	relay      ?string @[json: 'Relay']
	public_key ?string @[json: 'PublicKey']
}

// available options for filtering contracts
pub struct ContractFilter {
pub mut:
	contract_id          ?u64    @[json: 'ContractID']
	twin_id              ?u64    @[json: 'TwinID']
	node_id              ?u64    @[json: 'NodeID']
	type_                ?string @[json: 'Type']
	state                ?string @[json: 'State']
	name                 ?string @[json: 'Name']
	number_of_public_ips ?u64    @[json: 'NumberOfPublicIps']
	deployment_data      ?string @[json: 'DeploymentData']
	deployment_hash      ?string @[json: 'DeploymentHash']
}

pub struct NodesResult {
pub:
	nodes       []Node
	total_count int
}

pub struct FarmsResult {
pub:
	farms       []Farm
	total_count int
}

pub struct TwinsResult {
pub:
	twins       []Twin
	total_count int
}

pub struct ContractsResult {
pub:
	contracts   []Contract
	total_count int
}

pub struct Node {
pub:
	id                 string       @[json: 'id']
	node_id            int          @[json: 'nodeId']
	farm_id            int          @[json: 'farmId']
	twin_id            u64          @[json: 'twinId']
	country            string       @[json: 'country']
	grid_version       int          @[json: 'gridVersion']
	city               string       @[json: 'city']
	uptime             i64          @[json: 'uptime']
	created            i64          @[json: 'created']
	farming_policy_id  int          @[json: 'farmingPolicyId']
	updated_at         i64          @[json: 'updatedAt']
	total_resources    Capacity     @[json: 'total_resources']
	used_resources     Capacity     @[json: 'used_resources']
	location           Location     @[json: 'location']
	public_config      PublicConfig @[json: 'publicConfig']
	status             string       @[json: 'status']
	certification_type string       @[json: 'certificationType']
	dedicated          bool         @[json: 'dedicated']
	rent_contract_id   u32          @[json: 'rentContractId']
	rented_by_twin_id  u32          @[json: 'rentedByTwinId']
	serial_number      string       @[json: 'serialNumber']
}

pub struct Capacity {
pub:
	cru u64
	sru u64
	hru u64
	mru u64
}

pub struct Location {
pub:
	country   string
	city      string
	longitude f64
	latitude  f64
}

pub struct PublicConfig {
pub:
	domain string
	gw4    string
	gw6    string
	ipv4   string
	ipv6   string
}

pub struct Farm {
pub:
	name               string
	farm_id            int        @[json: 'farmId']
	twin_id            int        @[json: 'twinId']
	pricing_policy_id  int        @[json: 'pricingPolicyId']
	certification_type string     @[json: 'certificationType']
	stellar_address    string     @[json: 'stellarAddress']
	dedicated          bool       @[json: 'dedicated']
	public_ips         []PublicIP @[json: 'publicIps']
}

pub struct PublicIP {
pub:
	id          string
	ip          string
	farm_id     string
	contract_id int
	gateway     string
}

pub struct Twin {
pub:
	twin_id    u64    @[json: 'twinId']
	account_id string @[json: 'accountId']
	relay      string @[json: 'relay']
	public_key string @[json: 'publicKey']
}

pub struct Contract {
pub:
	contract_id u32               @[json: 'contractId']
	twin_id     u32               @[json: 'twinId']
	state       string            @[json: 'state']
	created_at  u32               @[json: 'created_at']
	type_       string            @[json: 'type']
	details     string            @[json: 'details']
	billing     []ContractBilling @[json: 'billing']
}

pub struct ContractBilling {
pub:
	amount_billed     u64
	discount_received string
	timestamp         u64
}

pub struct Statistics {
pub:
	nodes              i64
	farms              i64
	countries          i64
	total_cru          i64 @[json: 'totalCru']
	total_sru          i64 @[json: 'totalSru']
	total_mru          i64 @[json: 'totalMru']
	total_hru          i64 @[json: 'totalHru']
	public_ips         i64 @[json: 'publicIps']
	access_nodes       i64 @[json: 'accessNodes']
	gateways           i64
	twins              i64
	contracts          i64
	nodes_distribution map[string]i64 @[json: 'nodesDistribution']
}

@[params]
pub struct DeployDiscourse {
pub:
	name            string // identifier for the instance, must be unique
	farm_id         u64    // farm id to deploy on, if 0, a random eligible node on a random farm will be selected
	capacity        string // capacity of the instance. one of small, medium, large, extra-large
	disk_size       u32    // size of disk to mount on instance. must be in GB
	ssh_key         string // public ssh key to access the instance in a later stage
	developer_email string // developer email to get development emails, only works if smtp is configured
	public_ipv6     bool   // if true, a public ipv6 will be added to the instance
	// smtp server configurations
	smtp_username   string // smtp server username
	smtp_password   string // smtp server password
	smtp_address    string = 'smtp.gmail.com' // smtp server domain address
	smtp_port       u32    = 587              // smtp server port
	smtp_enable_tls bool // if true, tls encryption will be used in the smtp server
}

pub struct DiscourseDeployment {
pub:
	name         string // identifier for the instance
	planetary_ip string // instance planetary ip
	ipv6         string // instance ipv6, if any
	fqdn         string // fully qualified domain name pointing to the instance
}

@[params]
pub struct DeployFunkwhale {
pub:
	name        string // identifier for the instance, must be unique
	farm_id     u64    // farm id to deploy on, if 0, a random eligible node on a random farm will be selected
	capacity    string // capacity of the instance. one of small, medium, large, extra-large
	ssh_key     string // public ssh key to access the instance in a later stage
	public_ipv6 bool   // if true, a public ipv6 will be added to the instance
	// admin configuration
	admin_email    string @[required] // admin email to access admin dashboard
	admin_username string // admin username to access admin dashboard
	admin_password string // admin password to access admin dashboard
}

pub struct FunkwhaleDeployment {
pub:
	name         string // identifier for the instance
	planetary_ip string // instance planetary ip
	ipv6         string // instance ipv6, if any
	fqdn         string // fully qualified domain name pointing to the instance
}

@[params]
pub struct DeployPeertube {
pub:
	name        string // identifier for the instance, must be unique
	farm_id     u64    // farm id to deploy on, if 0, a random eligible farm will be selected
	capacity    string // capacity of the instance. one of small, medium, large, extra-large
	ssh_key     string // public ssh key to access the instance in a later stage
	public_ipv6 bool   // if true, a public ipv6 will be added to the instance
	// database configs
	db_username string // database username
	db_password string // database password

	admin_email string // admin email
}

pub struct PeertubeDeployment {
pub:
	name         string // identifier for the instance
	planetary_ip string // instance planetary ip
	ipv6         string // instance ipv6, if any
	fqdn         string // fully qualified domain name pointing to the instance
}

@[params]
pub struct DeployPresearch {
pub:
	name              string @[required] // identifier for the instance, must be unique
	farm_id           u64    // farm id to deploy on, if 0, a random eligible node on a random farm will be selected
	disk_size         u32    // size of disk to mount on instance. must be in GB
	ssh_key           string // public ssh key to access the instance in a later stage
	registration_code string @[required] // You need to sign up on Presearch in order to get your Presearch Registration Code.
	public_ipv4       bool // if true, a public ipv4 will be added to the instance
	public_ipv6       bool // if true, a public ipv6 will be added to the instance
	// presearch config for restoring old nodes
	public_restore_key  string
	private_restore_key string
}

pub struct PresearchDeployment {
pub:
	name         string // identifier for the instance
	planetary_ip string // instance planetary ip
	ipv6         string // instance ipv6, if any
	fqdn         string // fully qualified domain name pointing to the instance
}

@[params]
pub struct DeployTaiga {
pub:
	name        string // identifier for the instance, must be unique
	farm_id     u64    // farm id to deploy on, if 0, a random eligible node on a random farm will be selected
	capacity    string // capacity of the instance. one of small, medium, large, extra-large
	disk_size   u32    // size of disk to mount on instance. must be in GB
	ssh_key     string // public ssh key to access the instance in a later stage
	public_ipv6 bool   // if true, a public ipv6 will be added to the instance
	// admin configs
	admin_username string // admin username
	admin_password string // admin password
	admin_email    string // admin email
}

pub struct TaigaDeployment {
pub:
	name         string // identifier for the instance
	planetary_ip string // instance planetary ip
	ipv6         string // instance ipv6, if any
	fqdn         string // fully qualified domain name pointing to the instance
}

pub struct ZOSNodeRequest {
pub:
	node_id int
	data    u64
}

pub struct NodeStatistics {
pub:
	total Capacity
	used  Capacity
}

pub struct SystemTooling {
pub:
	aggregator string
	decoder    string
}

pub struct SystemPropertyData {
pub:
	value string
	items []string
}

pub struct SystemSubsection {
pub:
	title      string
	properties map[string]SystemPropertyData
}

pub struct SystemSection {
pub:
	handleline   string
	typestr      string
	section_type int @[json: 'type']
	subsections  []SystemSubsection
}

pub struct SystemDMI {
pub:
	tooling  SystemTooling
	sections []SystemSection
}

pub struct ZOSVersion {
pub:
	zos   string
	zinit string
}

pub struct WorkloadResult {
pub:
	created u32
	state   string
	message string
	data    u64
}

pub struct Workload {
pub:
	version       u32
	name          string
	workload_type string @[json: 'type']
	data          ZDBWorkload
	metadata      string
	description   string
	result        WorkloadResult
}

pub struct SignatureRequest {
	twin_id  u32
	required bool
	weight   u32
}

pub struct SignatureRequirement {
pub:
	weight_required int
	requests        []SignatureRequest
}

pub struct Deployment {
pub:
	version               u32
	twin_id               u32
	contract_id           u64
	metadata              string
	description           string
	expiration            u64
	signature_requirement SignatureRequirement
	workloads             []Workload
}

pub struct ZDBWorkload {
pub:
	password string
	mode     string
	size     u32
	public   bool
}
