module models

import json

pub struct GatewayFQDNProxy {
pub:
	tls_passthrough bool
	backends        []string // The backends of the gateway proxy. must be in the format ip:port if tls_passthrough is set, otherwise the format should be http://ip[:port]
	network         ?string  // Network name to join, if backend IP is private.
	fqdn            string   // The fully qualified domain name of the deployed workload.
}

pub fn (g GatewayFQDNProxy) challenge() string {
	mut output := ''
	output += g.fqdn
	output += '${g.tls_passthrough}'
	for b in g.backends {
		output += b
	}
	output += g.network or { '' }

	return output
}

pub fn (g GatewayFQDNProxy) to_workload(args WorkloadArgs) Workload {
	return Workload{
		version:     args.version or { 0 }
		name:        args.name
		type_:       workload_types.gateway_fqdn
		data:        json.encode(g)
		metadata:    args.metadata or { '' }
		description: args.description or { '' }
		result:      args.result or { WorkloadResult{} }
	}
}
