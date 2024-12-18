module model

pub struct GridStat {
pub:
	nodes              u64
	farms              u64
	countries          u64
	total_cru          u64      @[json: totalCru]
	total_sru          ByteUnit @[json: totalSru]
	total_mru          ByteUnit @[json: totalMru]
	total_hru          ByteUnit @[json: totalHru]
	public_ips         u64      @[json: publicIps]
	access_nodes       u64      @[json: accessNodes]
	gateways           u64
	twins              u64
	contracts          u64
	nodes_distribution map[string]u64 @[json: nodesDistribution]
}

pub struct NodeStatisticsResources {
pub:
	cru   u64
	hru   ByteUnit
	ipv4u u64
	mru   ByteUnit
	sru   ByteUnit
}

pub struct NodeStatisticsUsers {
pub:
	deployments u64
	workloads   u64
}

pub struct NodeStats {
pub:
	system NodeStatisticsResources

	total NodeStatisticsResources

	used NodeStatisticsResources

	users NodeStatisticsUsers
}
