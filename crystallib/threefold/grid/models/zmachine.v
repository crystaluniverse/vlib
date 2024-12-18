module models

import json

pub struct Zmachine {
pub mut:
	flist            string // if full url means custom flist meant for containers, if just name should be an official vm
	network          ZmachineNetwork
	size             u64 // size of the rootfs disk in bytes
	compute_capacity ComputeCapacity
	mounts           []Mount
	entrypoint       string            // how to invoke that in a vm?
	env              map[string]string // environment for the zmachine
	corex            bool
	gpu              []string
}

pub struct ZmachineNetwork {
pub mut:
	public_ip  string              // PublicIP optional public IP attached to this machine. If set it must be a valid name of a PublicIP workload in the same deployment
	interfaces []ZNetworkInterface // Interfaces list of user znets to join
	planetary  bool                // Planetary support planetary network
	mycelium   ?MyceliumIP
}

pub struct ZNetworkInterface {
pub mut:
	network string // Network name (znet name) to join
	ip      string // IP of the zmachine on this network must be a valid Ip in the selected network
}

pub struct MyceliumIP {
pub mut:
	network  string
	hex_seed string
}

pub fn (mut n ZmachineNetwork) challenge() string {
	mut out := ''
	out += n.public_ip
	out += n.planetary.str()

	for iface in n.interfaces {
		out += iface.network
		out += iface.ip
	}

	if m := n.mycelium {
		out += m.challenge()
	}
	return out
}

pub fn (m MyceliumIP) challenge() string {
	mut out := ''
	out += m.network
	out += m.hex_seed
	return out
}

pub struct Mount {
pub mut:
	name       string
	mountpoint string // the path to mount the disk into e.g. '/disk1'
}

pub fn (mut m Mount) challenge() string {
	mut out := ''
	out += m.name
	out += m.mountpoint
	return out
}

pub fn (mut m Zmachine) challenge() string {
	mut out := ''

	out += m.flist
	out += m.network.challenge()
	out += '${m.size}'
	out += m.compute_capacity.challenge()

	for mut mnt in m.mounts {
		out += mnt.challenge()
	}
	out += m.entrypoint

	mut keys := m.env.keys()
	keys.sort()
	for key in keys {
		out += key
		out += '='
		out += m.env[key]
	}
	return out
}

// response of the deployment
pub struct ZmachineResult {
pub mut:
	// name unique per deployment, re-used in request & response
	id           string
	ip           string
	planetary_ip string
	mycelium_ip  string
	console_url  string
}

pub fn (z Zmachine) to_workload(args WorkloadArgs) Workload {
	return Workload{
		version:     args.version or { 0 }
		name:        args.name
		type_:       workload_types.zmachine
		data:        json.encode(z)
		metadata:    args.metadata or { '' }
		description: args.description or { '' }
		result:      args.result or { WorkloadResult{} }
	}
}

// VM struct used to deploy machine in a high level manner
pub struct VM {
pub:
	name        string = 'myvm'
	flist       string = 'https://hub.grid.tf/tf-official-apps/base:latest.flist'
	entrypoint  string = '/sbin/zinit init'
	env_vars    map[string]string
	cpu         int = 1
	memory      int = 1024
	rootfs_size int
}

pub fn (vm VM) json_encode() string {
	mut env_vars := []string{}
	for k, v in vm.env_vars {
		env_vars << '"${k}": "${v}"'
	}

	return '{"name":"${vm.name}","flist":"${vm.flist}","entrypoint":"${vm.entrypoint}","env_vars":{${env_vars.join(',')}},"cpu":${vm.cpu},"memory":${vm.memory}, "rootfs_size": ${vm.rootfs_size}}'
}
