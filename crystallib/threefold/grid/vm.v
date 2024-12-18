module grid

import json
import log
import freeflowuniverse.crystallib.builder
import freeflowuniverse.crystallib.threefold.grid.models

struct VMSpecs {
	deployment_name  string
	name             string
	nodeid           u32
	pub_sshkeys      []string
	flist            string // if any, if used then ostype not used
	size             u32    // size of the rootfs disk in bytes
	compute_capacity models.ComputeCapacity
	ostype           OSType
}

enum OSType {
	ubuntu_22_04
	ubuntu_24_04
	arch
	alpine
}

struct VMDeployed {
	name         string
	nodeid       u32
	guid         string
	yggdrasil_ip string
	mycelium_ip  string
}

pub fn (vm VMDeployed) builder_node() !&builder.Node {
	mut factory := builder.new()!
	return factory.node_new(
		ipaddr: vm.mycelium_ip
	)!
}

// only connect to yggdrasil and mycelium
fn (mut deployer Deployer) vm_deploy(args_ VMSpecs) !VMDeployed {
	mut args := args_

	if args.pub_sshkeys.len == 0 {
		return error('at least one ssh key needed to deploy vm')
	}
	// deploymentstate_db.set(args.deployment_name,"vm_${args.name}",json.encode(VMDeployed))!

	vm := models.VM{
		name:     'vm1'
		env_vars: {
			'SSH_KEY': 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDTwULSsUubOq3VPWL6cdrDvexDmjfznGydFPyaNcn7gAL9lRxwFbCDPMj7MbhNSpxxHV2+/iJPQOTVJu4oc1N7bPP3gBCnF51rPrhTpGCt5pBbTzeyNweanhedkKDsCO2mIEh/92Od5Hg512dX4j7Zw6ipRWYSaepapfyoRnNSriW/s3DH/uewezVtL5EuypMdfNngV/u2KZYWoeiwhrY/yEUykQVUwDysW/xUJNP5o+KSTAvNSJatr3FbuCFuCjBSvageOLHePTeUwu6qjqe+Xs4piF1ByO/6cOJ8bt5Vcx0bAtI8/MPApplUU/JWevsPNApvnA/ntffI+u8DCwgP'
		}
	}

	mut env_vars := {
		'SSH_KEY': args.pub_sshkeys[0]
	}
	// QUESTION: how to implement multiple ssh keys
	for i, key in args.pub_sshkeys[0..] {
		env_vars['SSH_KEY${i}'] = key
	}

	machine := models.Zmachine{
		flist:            args.flist
		size:             args.size
		compute_capacity: args.compute_capacity
		env:              env_vars
	}

	mut deployment := models.new_deployment(
		// twin_id:
		workloads: [machine.to_workload()]
		metadata:  models.DeploymentData{
			name: args.deployment_name
		}
	)

	contract_id := deployer.deploy(args.nodeid, mut deployment, args.name, 0)!
	deployed := deployer.get_deployment(contract_id, args.nodeid)!
	if deployed.workloads.len < 1 {
		panic('deployment should have at least one workload for vm')
	}
	vm_workload := deployed.workloads[0]
	zmachine := json.decode(models.Zmachine, vm_workload.data)!
	mycelium_ip := zmachine.network.mycelium or { panic('deployed vm must have mycelium ip') }
	vm_deployed := VMDeployed{
		name:   vm_workload.name
		nodeid: args.nodeid
		guid:   vm_workload.name
		// yggdrasil_ip: zmachine.network.
		mycelium_ip: '${mycelium_ip.network}${mycelium_ip.hex_seed}'
	}

	return vm_deployed
}
