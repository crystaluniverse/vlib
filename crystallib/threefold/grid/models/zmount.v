// ssd mounts under zmachine

module models

import json

// ONLY possible on SSD
pub struct Zmount {
pub mut:
	size i64 // bytes
}

pub fn (mut mount Zmount) challenge() string {
	return '${mount.size}'
}

pub struct ZmountResult {
pub mut:
	volume_id string
}

pub fn (z Zmount) to_workload(args WorkloadArgs) Workload {
	return Workload{
		version:     args.version or { 0 }
		name:        args.name
		type_:       workload_types.zmount
		data:        json.encode(z)
		metadata:    args.metadata or { '' }
		description: args.description or { '' }
		result:      args.result or { WorkloadResult{} }
	}
}
