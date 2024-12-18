module models

import json

pub struct GatewayNameProxy {
pub:
	tls_passthrough bool
	backends        []string // The backends of the gateway proxy. must be in the format ip:port if tls_passthrough is set, otherwise the format should be http://ip[:port]
	network         ?string  // Network name to join, if backend IP is private.
	name            string   // Domain prefix. The fqdn will be <name>.<gateway-domain>.  This has to be unique within the deployment. Must contain only alphanumeric and underscore characters.
}

pub fn (g GatewayNameProxy) challenge() string {
	mut output := ''
	output += g.name
	output += '${g.tls_passthrough}'
	for b in g.backends {
		output += b
	}
	output += g.network or { '' }

	return output
}

// GatewayProxyResult results
pub struct GatewayProxyResult {
pub mut:
	fqdn string
}

pub fn (g GatewayNameProxy) to_workload(args WorkloadArgs) Workload {
	return Workload{
		version:     args.version or { 0 }
		name:        args.name
		type_:       workload_types.gateway_name
		data:        json.encode(g)
		metadata:    args.metadata or { '' }
		description: args.description or { '' }
		result:      args.result or { WorkloadResult{} }
	}
}
