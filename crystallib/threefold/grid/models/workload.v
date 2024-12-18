module models

import json
import crypto.md5

pub struct WorkloadTypes {
pub:
	zmachine     string = 'zmachine'
	zmount       string = 'zmount'
	network      string = 'network'
	zdb          string = 'zdb'
	public_ip    string = 'ip'
	qsfs         string = 'qsfs'
	gateway_name string = 'gateway-name-proxy'
	gateway_fqdn string = 'gateway-fqdn-proxy'
	zlogs        string = 'zlogs'
}

pub const workload_types = WorkloadTypes{}

type WorkloadType = string

pub struct ResultStates {
pub:
	error   ResultState = 'error'
	ok      ResultState = 'ok'
	deleted ResultState = 'deleted'
}

pub const result_states = ResultStates{}

type ResultState = string

pub fn challenge(data string, type_ string) !string {
	match type_ {
		workload_types.zmount {
			mut w := json.decode(Zmount, data)!
			return w.challenge()
		}
		workload_types.network {
			mut w := json.decode(Znet, data)!
			return w.challenge()
		}
		workload_types.zdb {
			mut w := json.decode(Zdb, data)!
			return w.challenge()
		}
		workload_types.zmachine {
			mut w := json.decode(Zmachine, data)!
			return w.challenge()
		}
		workload_types.qsfs {
			mut w := json.decode(QuantumSafeFS, data)!
			return w.challenge()
		}
		workload_types.public_ip {
			mut w := json.decode(PublicIP, data)!
			return w.challenge()
		}
		workload_types.gateway_name {
			mut w := json.decode(GatewayNameProxy, data)!
			return w.challenge()
		}
		workload_types.gateway_fqdn {
			mut w := json.decode(GatewayFQDNProxy, data)!
			return w.challenge()
		}
		workload_types.zlogs {
			mut w := json.decode(ZLogs, data)!
			return w.challenge()
		}
		else {
			return ''
		}
	}
}

pub enum Right {
	restart
	delete
	stats
	logs
}

// Access Control Entry
pub struct ACE {
	// the administrator twin id
	twin_ids []int
	rights   []Right
}

pub struct WorkloadResult {
pub mut:
	created i64
	state   ResultState
	error   string
	data    string @[raw] // also json.RawMessage
	message string
}

pub struct Workload {
pub mut:
	version u32
	// unique name per Deployment
	name  string
	type_ WorkloadType @[json: 'type']
	// this should be something like json.RawMessage in golang
	data        string @[raw] // serialize({size: 10}) ---> "data": {size:10},
	metadata    string
	description string
	// list of Access Control Entries
	// what can an administrator do
	// not implemented in zos
	// acl []ACE

	result WorkloadResult
}

pub fn (workload Workload) challenge() string {
	mut out := []string{}
	out << '${workload.version}'
	out << '${workload.name}'
	out << '${workload.type_}'
	out << '${workload.metadata}'
	out << '${workload.description}'
	out << challenge(workload.data, workload.type_) or { return out.join('') }

	return out.join('')
}

pub fn (workload Workload) challenge_hash() []u8 {
	return md5.sum(workload.challenge().bytes())
}

pub fn (mut w Workload) json_encode() string {
	return '{"version":${w.version},"name":"${w.name}","type":"${w.type_}","data":${w.data},"metadata":"${w.metadata}","description":"${w.description}"}'
}

type WorkloadData = GatewayFQDNProxy
	| GatewayNameProxy
	| PublicIP
	| QuantumSafeFS
	| ZLogs
	| Zdb
	| Zmachine
	| Zmount
	| Znet
type WorkloadDataResult = GatewayProxyResult
	| PublicIPResult
	| ZdbResult
	| ZmachineResult
	| ZmountResult

// pub fn(mut w WorkloadData) challenge() string {
// 	return w.challenge()
// }

@[params]
pub struct WorkloadArgs {
pub:
	version     ?u32
	name        string
	description ?string
	metadata    ?string
	result      ?WorkloadResult
}
