module tfrobot

import rand 

struct VMSpecs{
	deployment_name string
	name string
	nodeid u32
	pub_sshkeys []string
	flist string //if any, if used then ostype not used
	size u32 // size of the rootfs disk in bytes
	cores int // number of virtual cores
	memory u32 // ram in mb
	ostype OSType
}

enum OSType{
	ubuntu_22_04
	ubuntu_24_04
	arch
	alpine
}

//only connect to yggdrasil and mycelium
pub fn (mut robot TFRobot[Config]) vm_deploy(args_ VMSpecs) !VMOutput {
	mut args := args_

	if args.pub_sshkeys.len == 0 {
		return error('at least one ssh key needed to deploy vm')
	}

	size := if args.size < 20 {
		20
	} else {args.size}
	// deploymentstate_db.set(args.deployment_name,"vm_${args.name}",json.encode(VMDeployed))!

	mut ssh_keys := {'SSH_KEY': args.pub_sshkeys[0]}
	// QUESTION: how to implement multiple ssh keys
	for i, key in args.pub_sshkeys[0..] {
		ssh_keys['SSH_KEY${i}'] = key
	}

	flist := if args.flist == '' {
		'https://hub.grid.tf/samehabouelsaad.3bot/abouelsaad-grid3_ubuntu20.04-latest.flist'
	} else {args.flist}

	node_group := 'ng_${args.cores}_${args.memory}_${args.size}_${rand.string(8).to_lower()}'

	config := robot.config()!
	mneumonics := config.mnemonics
	output := robot.deploy(
		name: args.name
		mnemonic: mneumonics
		network: .main
		node_groups: [
			NodeGroup{
				name: node_group
				nodes_count: 1
				free_cpu: args.cores
				free_mru: args.memory
				free_ssd: size
			},
		]
		vms: [
			VMConfig{
				name: args.name
				vms_count: 1
				cpu: args.cores
				mem: args.memory
				root_size: size
				node_group: node_group
				ssh_key: 'SSH_KEY'
				flist: flist
      			entry_point: '/sbin/zinit init'
			},
		]
		ssh_keys: ssh_keys
	) or {return error('\nTFRobot deploy error:\n  - ${err}')}

	if output.ok.len < 1 {
		if output.error.len < 1 {
			panic('this should never happen')
		}

		err := output.error[output.error.keys()[0]]
		return error('failed to deploy vm ${err}')
	}

	vm_outputs := output.ok[output.ok.keys()[0]]
	if vm_outputs.len != 1 {
		panic('this should never happen ${vm_outputs}')
	}

	vm_output := vm_outputs[0]
	return vm_output
}