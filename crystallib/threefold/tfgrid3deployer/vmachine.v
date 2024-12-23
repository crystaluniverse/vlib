module tfgrid3deployer

import freeflowuniverse.crystallib.ui.console
import json
import os
import rand

@[params]
pub struct Mycelium {
	hex_seed string = rand.hex(12)
}

// MachineNetworkReq struct to represent network access configuration
@[params]
pub struct VMRequirements {
pub mut:
	name        string
	description string
	cpu         int // vcores
	memory      int // gbyte
	public_ip4  bool
	public_ip6  bool
	planetary   bool
	size        u64
	mycelium    ?Mycelium
	flist       string = 'https://hub.grid.tf/tf-official-vms/ubuntu-24.04-latest.flist'
	entrypoint  string = '/sbin/zinit init'
	env         map[string]string
	nodes       []u32 // if set will chose a node from the list to deploy on
}

// MachineModel struct to represent a machine and its associat	ed details
pub struct VMachine {
pub mut:
	tfchain_id   string
	contract_id  u64
	requirements VMRequirements
	node_id      u32
	planetary_ip string
	mycelium_ip  string
	public_ip4   string
	wireguard_ip string
	public_ip6   string
}

// Helper function to encode a VMachine
fn (self VMachine) encode() ![]u8 {
	// mut b := encoder.new()
	// b.add_string(self.name)
	// b.add_string(self.tfchain_id)
	// b.add_int(self.contract_id)
	// b.add_int(self.cpu)
	// b.add_int(self.memory)
	// b.add_string(self.description)
	// for now we just use json, will do bytes when needed
	return json.encode(self).bytes()
}

// Helper function to decode a VMachine
fn decode_vmachine(data []u8) !VMachine {
	// mut d encoder.Decode
	// return VMachine{
	// 	name:                d.get_string()
	// 	tfchain_id:          d.get_string()
	// 	contract_id: d.get_int()
	// 	cpu:                 d.get_int()
	// 	memory:              d.get_int()
	// 	description:         d.get_string()
	// }
	data_string := data.bytestr()
	return json.decode(VMachine, data_string)
}

// Call zos to get the zos version running on the node
fn (self VMachine) check_node_up() !bool {
	console.print_header('Pinging node: ${self.node_id}')
	mut deployer := get_deployer()!
	node_twin_id := deployer.client.get_node_twin(self.node_id) or {
		return error('faild to get the node twin ID due to: ${err}')
	}
	deployer.client.get_zos_version(node_twin_id) or { return false }
	console.print_header('Node ${self.node_id} is reachable.')
	return true
}

fn ping(ip string) bool {
	res := os.execute('ping -c 1 -W 2 ${ip}')
	return res.exit_code == 0
}

// Ping the VM supported interfaces
fn (self VMachine) check_vm_up() bool {
	if self.public_ip4 != '' {
		console.print_header('Pinging public IPv4: ${self.public_ip4}')
		pingable := ping(self.public_ip4)
		if !pingable {
			console.print_stderr("The public IPv4 isn't pingable.")
		}
		return pingable
	}

	if self.public_ip6 != '' {
		console.print_header('Pinging public IPv6: ${self.public_ip6}')
		pingable := ping(self.public_ip6)
		if !pingable {
			console.print_stderr("The public IPv6 isn't pingable.")
		}
		return pingable
	}

	if self.planetary_ip != '' {
		console.print_header('Pinging planetary IP: ${self.planetary_ip}')
		pingable := ping(self.planetary_ip)
		if !pingable {
			console.print_stderr("The planetary IP isn't pingable.")
		}
		return pingable
	}

	if self.mycelium_ip != '' {
		console.print_header('Pinging mycelium IP: ${self.mycelium_ip}')
		pingable := ping(self.mycelium_ip)
		if !pingable {
			console.print_stderr("The mycelium IP isn't pingable.")
		}
		return pingable
	}
	return false
}

pub fn (self VMachine) healthcheck() !bool {
	console.print_header('Doing a healthcheck on machine ${self.requirements.name}')

	is_vm_up := self.check_node_up()!
	if !is_vm_up {
		console.print_stderr("The VM isn't reachable, pinging node ${self.node_id}")
		is_node_up := self.check_node_up()!
		if !is_node_up {
			console.print_stderr("The VM node isn't reachable.")
			return false
		}
		return false
	}

	console.print_header('The VM is up and reachable.')
	return true
}

// NetworkInfo struct to represent network details
pub struct RecoverArgs {
pub mut:
	reinstall bool // reinstall if needed and run heroscript
}

fn (self VMachine) recover(args RecoverArgs) ! {
}

// NetworkInfo struct to represent network details
pub struct DeployArgs {
pub mut:
	reset bool // careful will delete existing machine if true
}

fn (self VMachine) deploy(args DeployArgs) ! {
	// check the machine is there, if yes and reset used then delete the machine before deploying a new one
}
