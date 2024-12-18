module models

import json

pub struct PublicIP {
pub:
	v4 bool
	v6 bool
}

pub fn (p PublicIP) challenge() string {
	mut output := ''
	output += '${p.v4}'
	output += '${p.v6}'

	return output
}

// PublicIPResult result returned by publicIP reservation
struct PublicIPResult {
pub mut:
	ip      string
	ip6     string
	gateway string
}

pub fn (p PublicIP) to_workload(args WorkloadArgs) Workload {
	return Workload{
		version:     args.version or { 0 }
		name:        args.name
		type_:       workload_types.public_ip
		data:        json.encode(p)
		metadata:    args.metadata or { '' }
		description: args.description or { '' }
		result:      args.result or { WorkloadResult{} }
	}
}
