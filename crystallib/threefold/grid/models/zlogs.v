module models

import json

pub struct ZLogs {
pub:
	zmachine string // zmachine name to stream logs of
	output   string // the `target` location to stream the logs to, it must be a redis or web-socket url
}

pub fn (z ZLogs) challenge() string {
	mut output := ''
	output += z.zmachine
	output += z.output

	return output
}

pub fn (z ZLogs) to_workload(args WorkloadArgs) Workload {
	return Workload{
		version:     args.version or { 0 }
		name:        args.name
		type_:       workload_types.zlogs
		data:        json.encode(z)
		metadata:    args.metadata or { '' }
		description: args.description or { '' }
		result:      args.result or { WorkloadResult{} }
	}
}
