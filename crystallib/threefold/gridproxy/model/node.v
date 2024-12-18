module model

pub struct NodeResources {
pub:
	cru u64
	mru ByteUnit
	sru ByteUnit
	hru ByteUnit
}

pub struct NodeCapacity {
pub:
	total_resources NodeResources
	used_resources  NodeResources
}

pub struct NodeLocation {
pub:
	country string
	city    string
}

pub struct PublicConfig {
pub:
	domain string
	gw4    string
	gw6    string
	ipv4   string
	ipv6   string
}

// this is ugly, but it works. we need two models for `Node` and reimplemnt the same fields expcept for capacity srtucture
// it's a hack to make the json parser work as the gridproxy API have some inconsistencies
// see for more context: https://github.com/threefoldtech/tfgridclient_proxy/issues/164
pub struct Node_ {
pub:
	id                string
	node_id           u64 @[json: nodeId]
	farm_id           u64 @[json: farmId]
	twin_id           u64 @[json: twinId]
	grid_version      u64 @[json: gridVersion]
	uptime            SecondUnit
	created           UnixTime @[json: created]
	farming_policy_id u64      @[json: farmingPolicyId]
	updated_at        UnixTime @[json: updatedAt]
	total_resources   NodeResources
	used_resources    NodeResources
	location          NodeLocation
	public_config     PublicConfig @[json: publicConfig]
	certification     string       @[json: certificationType]
	status            string
	dedicated         bool
	healthy           bool
	rent_contract_id  u64 @[json: rentContractId]
	rented_by_twin_id u64 @[json: rentedByTwinId]
}

pub struct Node {
pub:
	id                string
	node_id           u64 @[json: nodeId]
	farm_id           u64 @[json: farmId]
	twin_id           u64 @[json: twinId]
	grid_version      u64 @[json: gridVersion]
	uptime            SecondUnit
	created           UnixTime @[json: created]
	farming_policy_id u64      @[json: farmingPolicyId]
	updated_at        UnixTime @[json: updatedAt]
	capacity          NodeCapacity
	location          NodeLocation
	public_config     PublicConfig @[json: publicConfig]
	certification     string       @[json: certificationType]
	status            string
	dedicated         bool
	healthy           bool
	rent_contract_id  u64 @[json: rentContractId]
	rented_by_twin_id u64 @[json: rentedByTwinId]
}

fn calc_available_resources(total_resources NodeResources, used_resources NodeResources) NodeResources {
	return NodeResources{
		cru: total_resources.cru - used_resources.cru
		mru: total_resources.mru - used_resources.mru
		sru: total_resources.sru - used_resources.sru
		hru: total_resources.hru - used_resources.hru
	}
}

// calc_available_resources calculate the reservable capacity of the node.
//
// Returns: `NodeResources`
pub fn (n &Node) calc_available_resources() NodeResources {
	total_resources := n.capacity.total_resources
	used_resources := n.capacity.used_resources
	return calc_available_resources(total_resources, used_resources)
}

// with_nested_capacity enable the client to have one representation of the node model
pub fn (n &Node_) with_nested_capacity() Node {
	return Node{
		id:                n.id
		node_id:           n.node_id
		farm_id:           n.farm_id
		twin_id:           n.twin_id
		grid_version:      n.grid_version
		uptime:            n.uptime
		created:           n.created
		farming_policy_id: n.farming_policy_id
		updated_at:        n.updated_at
		capacity:          NodeCapacity{
			total_resources: n.total_resources
			used_resources:  n.used_resources
		}
		location:          n.location
		public_config:     n.public_config
		certification:     n.certification
		status:            n.status
		dedicated:         n.dedicated
		healthy:           n.healthy
		rent_contract_id:  n.rent_contract_id
		rented_by_twin_id: n.rented_by_twin_id
	}
}

// is_online returns true if the node is online, otherwise false.
pub fn (n &Node) is_online() bool {
	return n.status == 'up'
}
