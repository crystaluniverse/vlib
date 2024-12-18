module deploy

import freeflowuniverse.crystallib.threefold.grid.models as grid_models
import freeflowuniverse.crystallib.data.paramsparser
import freeflowuniverse.crystallib.threefold.grid
import freeflowuniverse.crystallib.data.encoder
import freeflowuniverse.crystallib.ui.console
import rand
import json
import encoding.base64
import os

@[heap]
pub struct TFDeployment {
pub mut:
	name        string = 'default'
	description string
	vms         []VMachine
mut:
	deployer ?grid.Deployer @[skip; str: skip]
}

fn (mut self TFDeployment) new_deployer() !grid.Deployer {
	if self.deployer == none {
		mut grid_client := get()!
		network := match grid_client.network {
			.dev { grid.ChainNetwork.dev }
			.test { grid.ChainNetwork.test }
			.main { grid.ChainNetwork.main }
		}
		self.deployer = grid.new_deployer(grid_client.mnemonic, network)!
	}
	return self.deployer or { return error('Deployer not initialized') }
}

pub fn (mut self TFDeployment) vm_deploy(args_ VMRequirements) !VMachine {
	console.print_header('Starting deployment process.')

	mut deployer := self.new_deployer() or { return error('Failed to initialize deployer: ${err}') }

	mut node_id := get_node_id(args_) or { return error('Failed to determine node ID: ${err}') }

	mut network := args_.network or {
		NetworkSpecs{
			name:     'net' + rand.string(5)
			ip_range: '10.249.0.0/16'
			subnet:   '10.249.0.0/24'
		}
	}

	wg_port := deployer.assign_wg_port(node_id)!
	workloads := create_workloads(args_, network, wg_port)!

	console.print_header('Creating deployment.')
	mut deployment := grid_models.new_deployment(
		twin_id:               deployer.twin_id
		description:           'VGridClient Deployment'
		workloads:             workloads
		signature_requirement: create_signature_requirement(deployer.twin_id)
	)

	console.print_header('Setting metadata and deploying workloads.')
	deployment.add_metadata('vm', args_.name)
	contract_id := deployer.deploy(node_id, mut deployment, deployment.metadata, 0) or {
		return error('Deployment failed: ${err}')
	}

	console.print_header('Deployment successful. Contract ID: ${contract_id}')

	vm := VMachine{
		tfchain_id:          '${deployer.twin_id}${args_.name}'
		tfchain_contract_id: int(contract_id)
		requirements:        VMRequirements{
			name:        args_.name
			description: args_.description
			cpu:         args_.cpu
			memory:      args_.memory
		}
	}

	self.name = args_.name
	self.description = args_.description
	self.vms << vm

	self.save()!
	self.load(args_.name)!
	return vm
}

fn get_node_id(args_ VMRequirements) !u32 {
	if args_.nodes.len == 0 {
		console.print_header('Requesting the proxy to filter nodes.')
		nodes := nodefilter(args_)!
		if nodes.len == 0 {
			return error('No suitable nodes found.')
		}
		return u32(nodes[0].node_id)
	}
	return u32(args_.nodes[0])
}

fn create_workloads(args_ VMRequirements, network NetworkSpecs, wg_port u32) ![]grid_models.Workload {
	mut workloads := []grid_models.Workload{}

	workloads << create_network_workload(network, wg_port)!
	mut public_ip_name := ''
	if args_.public_ip4 || args_.public_ip6 {
		public_ip_name = rand.string(5).to_lower()
		workloads << create_public_ip_workload(args_.public_ip4, args_.public_ip6, public_ip_name)
	}

	zmachine := create_zmachine_workload(args_, network, public_ip_name)!
	workloads << zmachine.to_workload(
		name:        args_.name
		description: args_.description
	)

	return workloads
}

fn create_signature_requirement(twin_id int) grid_models.SignatureRequirement {
	console.print_header('Setting signature requirement.')
	return grid_models.SignatureRequirement{
		weight_required: 1
		requests:        [
			grid_models.SignatureRequest{
				twin_id: u32(twin_id)
				weight:  1
			},
		]
	}
}

fn create_network_workload(network NetworkSpecs, wg_port u32) !grid_models.Workload {
	console.print_header('Creating network workload.')
	return grid_models.Znet{
		ip_range:              network.ip_range
		subnet:                network.subnet
		wireguard_private_key: 'GDU+cjKrHNJS9fodzjFDzNFl5su3kJXTZ3ipPgUjOUE='
		wireguard_listen_port: u16(wg_port)
		mycelium:              grid_models.Mycelium{
			hex_key: rand.string(32).bytes().hex()
		}
		peers:                 [
			grid_models.Peer{
				subnet:               network.subnet
				wireguard_public_key: '4KTvZS2KPWYfMr+GbiUUly0ANVg8jBC7xP9Bl79Z8zM='
				allowed_ips:          [network.subnet]
			},
		]
	}.to_workload(
		name:        network.name
		description: 'VGridClient Network'
	)
}

fn create_public_ip_workload(is_v4 bool, is_v6 bool, name string) grid_models.Workload {
	console.print_header('Creating Public IP workload.')
	return grid_models.PublicIP{
		v4: is_v4
		v6: is_v6
	}.to_workload(name: name)
}

fn create_zmachine_workload(args_ VMRequirements, network NetworkSpecs, public_ip_name string) !grid_models.Zmachine {
	console.print_header('Creating Zmachine workload.')
	mut grid_client := get()!

	return grid_models.Zmachine{
		network:          grid_models.ZmachineNetwork{
			interfaces: [
				grid_models.ZNetworkInterface{
					network: network.name
					ip:      network.ip_range.split('/')[0]
				},
			]
			public_ip:  public_ip_name
			planetary:  args_.planetary
			mycelium:   grid_models.MyceliumIP{
				network:  network.name
				hex_seed: rand.string(6).bytes().hex()
			}
		}
		flist:            'https://hub.grid.tf/tf-official-vms/ubuntu-24.04-latest.flist'
		entrypoint:       '/sbin/zinit init'
		compute_capacity: grid_models.ComputeCapacity{
			cpu:    u8(args_.cpu)
			memory: i64(args_.memory) * 1024 * 1024 * 1024
		}
		env:              {
			'SSH_KEY': grid_client.ssh_key
		}
	}
}

pub fn (mut self TFDeployment) vm_get(name string) ![]VMachine {
	d := self.load(name)!
	return d.vms
}

pub fn (mut self TFDeployment) load(deployment_name string) !TFDeployment {
	path := '${os.home_dir()}/hero/var/tfgrid/deploy/'
	filepath := '${path}${deployment_name}'
	base64_string := os.read_file(filepath) or {
		return error('Failed to open file due to: ${err}')
	}
	bytes := base64.decode(base64_string)
	d := self.decode(bytes)!
	return d
}

fn (mut self TFDeployment) save() ! {
	dir_path := '${os.home_dir()}/hero/var/tfgrid/deploy/'
	os.mkdir_all(dir_path)!
	file_path := dir_path + self.name

	encoded_data := self.encode() or { return error('Failed to encode deployment data: ${err}') }
	base64_string := base64.encode(encoded_data)

	os.write_file(file_path, base64_string) or { return error('Failed to write to file: ${err}') }
}

fn (self TFDeployment) encode() ![]u8 {
	mut b := encoder.new()
	b.add_string(self.name)
	b.add_int(self.vms.len)

	for vm in self.vms {
		vm_data := vm.encode()!
		b.add_int(vm_data.len)
		b.add_bytes(vm_data)
	}

	return b.data
}

fn (self TFDeployment) decode(data []u8) !TFDeployment {
	if data.len == 0 {
		return error('Data cannot be empty')
	}

	mut d := encoder.decoder_new(data)
	mut result := TFDeployment{
		name: d.get_string()
	}

	num_vms := d.get_int()

	for _ in 0 .. num_vms {
		d.get_int()
		vm_data := d.get_bytes()
		mut dd := encoder.decoder_new(vm_data)
		vm := decode_vmachine(dd.data)!
		result.vms << vm
	}

	return result
}
