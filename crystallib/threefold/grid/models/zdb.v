module models

import json

pub type ZdbMode = string

pub struct ZdbModes {
pub:
	seq  string = 'seq'
	user string = 'user'
}

pub const zdb_modes = ZdbModes{}

type DeviceType = string

pub struct DeviceTypes {
pub:
	hdd string = 'hdd'
	ssd string = 'ssd'
}

pub const device_types = DeviceTypes{}

pub struct Zdb {
pub mut:
	// size in bytes
	size     u64
	mode     ZdbMode
	password string
	public   bool
}

pub fn (mut z Zdb) challenge() string {
	mut out := ''
	out += '${z.size}'
	out += '${z.mode}'
	out += z.password
	out += '${z.public}'

	return out
}

pub struct ZdbResult {
pub mut:
	namespace string   @[json: 'Namespace']
	ips       []string @[json: 'IPs']
	port      u32      @[json: 'Port']
}

pub fn (z Zdb) to_workload(args WorkloadArgs) Workload {
	return Workload{
		version:     args.version or { 0 }
		name:        args.name
		type_:       workload_types.zdb
		data:        json.encode(z)
		metadata:    args.metadata or { '' }
		description: args.description or { '' }
		result:      args.result or { WorkloadResult{} }
	}
}
