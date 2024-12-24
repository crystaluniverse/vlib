// This file should only contains any functions, helpers that related to the deployment setup.
module tfgrid3deployer

import freeflowuniverse.crystallib.threefold.grid.models as grid_models
import freeflowuniverse.crystallib.threefold.grid
import freeflowuniverse.crystallib.ui.console
import rand

// a struct that prepare the setup for the deployment
struct DeploymentSetup {
mut:
	workloads       map[u32][]grid_models.Workload
	network_handler NetworkHandler

	deployer          &grid.Deployer @[skip; str: skip]
	contracts_map     map[u32]u64
	name_contract_map map[string]u64
}

// Sets up a new deployment with network, VM, and ZDB workloads.
// Parameters:
// - network_specs: NetworkSpecs struct containing network setup specifications
// - vms: Array of VMachine instances representing the virtual machines to set up workloads for
// - zdbs: Array of ZDB objects containing ZDB requirements
// - webnames: Array of WebName instances representing web names
// - deployer: Reference to the grid.Deployer for deployment operations
// Modifies:
// - dls: Modified DeploymentSetup struct with network, VM, and ZDB workloads set up
// Returns:
// - None
fn new_deployment_setup(network_specs NetworkSpecs, vms []VMachine, zdbs []ZDB, webnames []WebName, old_deployments map[u32]grid_models.Deployment, mut deployer grid.Deployer) !DeploymentSetup {
	mut dls := DeploymentSetup{
		deployer:        deployer
		network_handler: NetworkHandler{
			deployer:     deployer
			network_name: network_specs.name
			mycelium:     network_specs.mycelium
			ip_range:     network_specs.ip_range
		}
	}

	dls.setup_network_workloads(vms, old_deployments)!
	dls.setup_vm_workloads(vms)!
	dls.setup_zdb_workloads(zdbs)!
	dls.setup_webname_workloads(webnames)!
	dls.match_versions(old_deployments)
	return dls
}

fn (mut self DeploymentSetup) match_versions(old_dls map[u32]grid_models.Deployment) {
	for node_id, dl in old_dls {
		mut wl_versions := map[string]u32{}
		for wl in dl.workloads {
			wl_versions['${wl.name}:${wl.type_}'] = wl.version
		}

		for mut wl in self.workloads[node_id] {
			wl.version = wl_versions['${wl.name}:${wl.type_}']
		}
	}
}

// Sets up network workloads for the deployment setup.
// Parameters:
// - vms: Array of VMachine instances representing the virtual machines to set up workloads for
// Modifies:
// - st: Modified DeploymentSetup struct with network workloads set up
// Returns:
// - None
fn (mut st DeploymentSetup) setup_network_workloads(vms []VMachine, old_deployments map[u32]grid_models.Deployment) ! {
	st.network_handler.load_network_state(old_deployments)!
	st.network_handler.create_network(vms)!
	println('Network handler: ${st.network_handler}')
	data := st.network_handler.generate_workloads()!

	for node_id, workload in data {
		st.workloads[node_id] << workload
	}
}

// Sets up VM workloads for the deployment setup.
//
// This method iterates over a list of VMachines, processes each machine's requirements,
// sets up public IP if required, creates a Zmachine workload, and updates the used IP octets map.
//
// Parameters:
// - machines: Array of VMachine instances representing the virtual machines to set up workloads for
// Modifies:
// - self: Modified DeploymentSetup struct with VM workloads set up
// - used_ip_octets: Map of u32 to arrays of u8 representing used IP octets
// Returns:
// - None
fn (mut self DeploymentSetup) setup_vm_workloads(machines []VMachine) ! {
	mut used_ip_octets := map[u32][]u8{}
	for machine in machines {
		mut req := machine.requirements
		mut public_ip_name := ''

		if req.public_ip4 || req.public_ip6 {
			public_ip_name = '${req.name}_pubip'
			self.set_public_ip_workload(machine.node_id, public_ip_name, req)!
		}

		console.print_header('Creating Zmachine workload.')
		self.set_zmachine_workload(machine, public_ip_name, mut used_ip_octets)!
	}
}

// Sets up Zero-DB (ZDB) workloads for deployment.
//
// This function takes a list of ZDB results, processes each result into a ZDB workload model,
// assigns it to a healthy node, and then adds it to the deployment workloads.
//
// `zdbs`: A list of ZDB objects containing the ZDB requirements.
//
// Each ZDB is processed to convert the requirements into a grid workload and associated with a healthy node.
fn (mut self DeploymentSetup) setup_zdb_workloads(zdbs []ZDB) ! {
	for zdb in zdbs {
		// Retrieve ZDB requirements from the result
		mut req := zdb.requirements
		console.print_header('Creating a ZDB workload for `${req.name}` DB.')

		// Create the Zdb model with the size converted to bytes
		zdb_model := grid_models.Zdb{
			size:     convert_to_gigabytes(req.size) // Convert size from MB to bytes
			mode:     req.mode
			public:   req.public
			password: req.password
		}

		// Generate a workload based on the Zdb model
		zdb_workload := zdb_model.to_workload(
			name:        req.name
			description: req.description
		)

		// Append the workload to the node's workload list in the deployment setup
		self.workloads[zdb.node_id] << zdb_workload
	}
}

// Sets up web name workloads for the deployment setup.
//
// This method processes each WebName instance in the provided array, sets up gateway name proxies based on the requirements,
// and adds the gateway name proxy workload to the deployment workloads. It also updates the name contract map accordingly.
//
// Parameters:
// - webnames: Array of WebName instances representing web names to set up workloads for
// Modifies:
// - self: Modified DeploymentSetup struct with web name workloads set up
// Returns:
// - None
fn (mut self DeploymentSetup) setup_webname_workloads(webnames []WebName) ! {
	for wn in webnames {
		req := wn.requirements

		gw_name := if req.name == '' {
			rand.string(5).to_lower()
		} else {
			req.name
		}

		gw := grid_models.GatewayNameProxy{
			tls_passthrough: req.tls_passthrough
			backends:        [req.backend]
			name:            gw_name
		}

		self.workloads[wn.node_id] << gw.to_workload(
			name: gw_name
		)
		self.name_contract_map[gw_name] = wn.name_contract_id
	}
}

// Sets up a Zmachine workload for the deployment setup.
//
// This method prepares a Zmachine workload based on the provided VMachine, assigns private and public IPs,
// sets up Mycelium IP if required, and configures compute capacity and environment variables.
//
// Parameters:
// - vmachine: VMachine instance representing the virtual machine for which the workload is being set up
// - public_ip_name: Name of the public IP to assign to the Zmachine
// - used_ip_octets: Map of u32 to arrays of u8 representing used IP octets
// Throws:
// - Error if grid client is not available or if there are issues setting up the workload
fn (mut self DeploymentSetup) set_zmachine_workload(vmachine VMachine, public_ip_name string, mut used_ip_octets map[u32][]u8) ! {
	mut grid_client := get()!
	mut env_map := vmachine.requirements.env.clone()
	env_map['SSH_KEY'] = grid_client.ssh_key

	zmachine_workload := grid_models.Zmachine{
		network:          grid_models.ZmachineNetwork{
			interfaces: [
				grid_models.ZNetworkInterface{
					network: self.network_handler.network_name
					ip:      if vmachine.wireguard_ip.len > 0 {
						used_ip_octets[vmachine.node_id] << vmachine.wireguard_ip.all_after_last('.').u8()
						vmachine.wireguard_ip
					} else {
						self.assign_private_ip(vmachine.node_id, mut used_ip_octets)!
					}
				},
			]
			public_ip:  public_ip_name
			planetary:  vmachine.requirements.planetary
			mycelium:   if mycelium := vmachine.requirements.mycelium {
				grid_models.MyceliumIP{
					network:  self.network_handler.network_name
					hex_seed: mycelium.hex_seed
				}
			} else {
				none
			}
		}
		size:             convert_to_gigabytes(vmachine.requirements.size)
		flist:            vmachine.requirements.flist
		entrypoint:       vmachine.requirements.entrypoint
		compute_capacity: grid_models.ComputeCapacity{
			cpu:    u8(vmachine.requirements.cpu)
			memory: i64(convert_to_gigabytes(vmachine.requirements.memory))
		}
		env:              env_map
	}.to_workload(
		name:        vmachine.requirements.name
		description: vmachine.requirements.description
	)

	self.workloads[vmachine.node_id] << zmachine_workload
}

// Sets up a public IP workload for a specific node.
//
// This method creates a PublicIP workload based on the provided VMRequirements,
// assigns IPv4 and IPv6 addresses, and adds the workload to the DeploymentSetup workloads for the specified node.
//
// Parameters:
// - node_id: u32 representing the node ID where the public IP workload will be set up
// - public_ip_name: Name of the public IP to assign to the workload
fn (mut self DeploymentSetup) set_public_ip_workload(node_id u32, public_ip_name string, vm VMRequirements) ! {
	// Add the public IP workload
	console.print_header('Creating Public IP workload.')
	public_ip_workload := grid_models.PublicIP{
		v4: vm.public_ip4
		v6: vm.public_ip6
	}.to_workload(name: public_ip_name)

	self.workloads[node_id] << public_ip_workload
}

// Assigns a private IP to a specified node based on the provided node ID and used IP octets map.
//
// Parameters:
// - node_id: u32 representing the node ID to assign the private IP to
// - used_ip_octets: Map of u32 to arrays of u8 representing the used IP octets for each node
// Returns:
// - string: The assigned private IP address
// Throws:
// - Error if failed to assign a private IP in the subnet
fn (mut self DeploymentSetup) assign_private_ip(node_id u32, mut used_ip_octets map[u32][]u8) !string {
	console.print_header('Assign private IP to node ${node_id}.')
	ip := self.network_handler.wg_subnet[node_id].split('/')[0]
	mut split_ip := ip.split('.')
	last_octet := ip.split('.').last().u8()
	for candidate := last_octet + 2; candidate < 255; candidate += 1 {
		if candidate in used_ip_octets[node_id] {
			continue
		}
		split_ip[3] = '${candidate}'
		used_ip_octets[node_id] << candidate
		ip_ := split_ip.join('.')
		console.print_header('Private IP Assigned: ${ip_}.')
		return ip_
	}
	return error('failed to assign private IP in subnet: ${self.network_handler.wg_subnet[node_id]}')
}

/*
	TODO's:
		# TODO:
		- add action methods e.g. delete, ping...
		- cache node and user twin ids
		- chainge the encoding/decoding behavior

		# Done:
		- return result after deployment
		- use batch calls for substrate
		- send deployments to nodes concurrently
		- add roll back behavior
*/
