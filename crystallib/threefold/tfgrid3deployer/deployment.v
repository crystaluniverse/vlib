module tfgrid3deployer

import freeflowuniverse.crystallib.threefold.grid.models as grid_models
import freeflowuniverse.crystallib.threefold.grid
import freeflowuniverse.crystallib.ui.console
import compress.zlib
import encoding.hex
import x.crypto.chacha20
import crypto.sha256
import json
import rand

struct GridContracts {
pub mut:
	name []u64
	node map[string]u64
	rent map[string]u64
}

@[heap]
pub struct TFDeployment {
pub mut:
	name        string
	description string
	vms         []VMachine
	zdbs        []ZDB
	webnames    []WebName
	network     NetworkSpecs
mut:
	// Set the deployed contracts on the deployment and save the full deployment to be able to delete the whole deployment when need.
	contracts GridContracts
	deployer  &grid.Deployer @[skip; str: skip]
	kvstore   KVStoreFS      @[skip; str: skip]
}

fn get_deployer() !grid.Deployer {
	mut grid_client := get()!

	network := match grid_client.network {
		.dev { grid.ChainNetwork.dev }
		.qa { grid.ChainNetwork.qa }
		.test { grid.ChainNetwork.test }
		.main { grid.ChainNetwork.main }
	}

	return grid.new_deployer(grid_client.mnemonic, network)!
}

pub fn new_deployment(name string) !TFDeployment {
	kvstore := KVStoreFS{}

	if _ := kvstore.get(name) {
		return error('Deployment with the same name is already exist.')
	}

	deployer := get_deployer()!
	return TFDeployment{
		name:     name
		kvstore:  KVStoreFS{}
		deployer: &deployer
	}
}

pub fn get_deployment(name string) !TFDeployment {
	mut deployer := get_deployer()!
	mut dl := TFDeployment{
		name:     name
		kvstore:  KVStoreFS{}
		deployer: &deployer
	}

	dl.load() or { return error('Faild to load the deployment due to: ${err}') }

	return dl
}

pub fn (mut self TFDeployment) deploy() ! {
	console.print_header('Starting deployment process.')
	self.set_nodes()!
	old_deployment := self.list_deployments()!

	println('old_deployment ${old_deployment}')

	mut setup := new_deployment_setup(self.network, self.vms, self.zdbs, self.webnames,
		old_deployment, mut self.deployer)!

	// Check we are in which state
	self.finalize_deployment(setup)!
	self.save()!
}

fn (mut self TFDeployment) set_nodes() ! {
	for mut vm in self.vms {
		mut node_ids := []u64{}

		for node_id in vm.requirements.nodes {
			node_ids << u64(node_id)
		}

		nodes := filter_nodes(
			node_ids:  node_ids
			healthy:   true
			free_mru:  u64(vm.requirements.memory) * 1024 * 1024 * 1024
			total_cru: u64(vm.requirements.cpu)
			free_ips:  if vm.requirements.public_ip4 { u64(1) } else { none }
			has_ipv6:  if vm.requirements.public_ip6 { vm.requirements.public_ip6 } else { none }
			status:    'up'
		)!

		if nodes.len == 0 {
			if node_ids.len != 0 {
				return error("The provided vm nodes ${node_ids} don't have enough resources.")
			}
			return error('Requested the Grid Proxy and no nodes found.')
		}
		idx := rand.u32() % nodes.len
		// println('chodes node: ${}')
		vm.node_id = u32(nodes[idx].node_id)
	}

	for mut zdb in self.zdbs {
		size := u64(zdb.requirements.size) * 1024 * 1024 * 1024
		nodes := filter_nodes(
			free_sru: size
			status:   'up'
			healthy:  true
			node_id:  zdb.requirements.node_id
		)!

		if nodes.len == 0 {
			return error('Requested the Grid Proxy and no nodes found.')
		}

		zdb.node_id = u32(nodes[0].node_id)
	}

	for mut webname in self.webnames {
		nodes := filter_nodes(
			domain:  true
			status:  'up'
			healthy: true
			node_id: webname.requirements.node_id
		)!

		if nodes.len == 0 {
			return error('Requested the Grid Proxy and no nodes found.')
		}

		webname.node_id = u32(nodes[0].node_id)
	}
}

fn (mut self TFDeployment) finalize_deployment(setup DeploymentSetup) ! {
	mut new_deployments := map[u32]&grid_models.Deployment{}
	old_deployments := self.list_deployments()!
	mut current_contracts := []u64{}
	mut create_deployments := map[u32]&grid_models.Deployment{}

	for node_id, workloads in setup.workloads {
		console.print_header('Creating deployment on node ${node_id}.')
		mut deployment := grid_models.new_deployment(
			twin_id:               setup.deployer.twin_id
			description:           'VGridClient Deployment'
			workloads:             workloads
			signature_requirement: grid_models.SignatureRequirement{
				weight_required: 1
				requests:        [
					grid_models.SignatureRequest{
						twin_id: u32(setup.deployer.twin_id)
						weight:  1
					},
				]
			}
		)

		if d := old_deployments[node_id] {
			deployment.version = d.version
			deployment.contract_id = d.contract_id
			current_contracts << d.contract_id
		} else {
			create_deployments[node_id] = &deployment
		}

		deployment.add_metadata('VGridClient/Deployment', self.name)
		new_deployments[node_id] = &deployment
	}

	mut create_name_contracts := []string{}
	mut delete_contracts := []u64{}

	mut returned_deployments := map[u32]&grid_models.Deployment{}
	mut name_contracts_map := setup.name_contract_map.clone()

	// Create stage.
	for contract_name, contract_id in setup.name_contract_map {
		if contract_id == 0 {
			create_name_contracts << contract_name
		}
	}

	if create_name_contracts.len > 0 || create_deployments.len > 0 {
		console.print_header('Batch deploying the deployment')
		created_name_contracts_map, ret_dls := self.deployer.batch_deploy(create_name_contracts, mut
			create_deployments, none)!

		for node_id, deployment in ret_dls {
			returned_deployments[node_id] = deployment
		}

		for contract_name, contract_id in created_name_contracts_map {
			name_contracts_map[contract_name] = contract_id
		}
	}

	// Cancel stage.
	for contract_id in self.contracts.name {
		if !setup.name_contract_map.values().contains(contract_id) {
			delete_contracts << contract_id
		}
	}

	for node_id, dl in old_deployments {
		if _ := new_deployments[node_id] {
			continue
		}
		delete_contracts << dl.contract_id
	}

	if delete_contracts.len > 0 {
		self.deployer.client.batch_cancel_contracts(delete_contracts)!
	}

	// Update stage.
	for node_id, mut dl in new_deployments {
		mut deployment := *dl
		if _ := old_deployments[node_id] {
			self.deployer.update_deployment(node_id, mut deployment, dl.metadata)!
			returned_deployments[node_id] = deployment
		}
	}

	self.update_state(name_contracts_map, returned_deployments)!
}

fn (mut self TFDeployment) update_state(name_contracts_map map[string]u64, dls map[u32]&grid_models.Deployment) ! {
	mut workloads := map[u32]map[string]&grid_models.Workload{}

	for node_id, deployment in dls {
		workloads[node_id] = map[string]&grid_models.Workload{}
		for id, _ in deployment.workloads {
			workloads[node_id][deployment.workloads[id].name] = &deployment.workloads[id]
		}
	}

	self.contracts = GridContracts{}
	for _, contract_id in name_contracts_map {
		self.contracts.name << contract_id
	}

	for node_id, dl in dls {
		self.contracts.node['${node_id}'] = dl.contract_id
	}

	for mut vm in self.vms {
		vm_workload := workloads[vm.node_id][vm.requirements.name]
		res := json.decode(grid_models.ZmachineResult, vm_workload.result.data)!
		vm.mycelium_ip = res.mycelium_ip
		vm.planetary_ip = res.planetary_ip
		vm.wireguard_ip = res.ip
		vm.contract_id = dls[vm.node_id].contract_id

		if vm.requirements.public_ip4 || vm.requirements.public_ip6 {
			ip_workload := workloads[vm.node_id]['${vm.requirements.name}_pubip']
			ip_res := json.decode(grid_models.PublicIPResult, ip_workload.result.data)!
			vm.public_ip4 = ip_res.ip
			vm.public_ip6 = ip_res.ip6
		}
	}

	for mut zdb in self.zdbs {
		zdb_workload := workloads[zdb.node_id][zdb.requirements.name]
		res := json.decode(grid_models.ZdbResult, zdb_workload.result.data)!
		zdb.ips = res.ips
		zdb.namespace = res.namespace
		zdb.port = res.port
		zdb.contract_id = dls[zdb.node_id].contract_id
	}

	for mut wn in self.webnames {
		wn_workload := workloads[wn.node_id][wn.requirements.name]
		res := json.decode(grid_models.GatewayProxyResult, wn_workload.result.data)!
		wn.fqdn = res.fqdn
		wn.node_contract_id = dls[wn.node_id].contract_id
		wn.name_contract_id = name_contracts_map[wn.requirements.name]
	}
}

pub fn (mut self TFDeployment) vm_get(vm_name string) !VMachine {
	console.print_header('Getting ${vm_name} VM.')
	for vmachine in self.vms {
		if vmachine.requirements.name == vm_name {
			return vmachine
		}
	}
	return error('Machine does not exist.')
}

pub fn (mut self TFDeployment) zdb_get(zdb_name string) !ZDB {
	console.print_header('Getting ${zdb_name} Zdb.')
	for zdb in self.zdbs {
		if zdb.requirements.name == zdb_name {
			return zdb
		}
	}
	return error('Zdb does not exist.')
}

pub fn (mut self TFDeployment) webname_get(wn_name string) !WebName {
	console.print_header('Getting ${wn_name} webname.')
	for wbn in self.webnames {
		if wbn.requirements.name == wn_name {
			return wbn
		}
	}
	return error('Webname does not exist.')
}

pub fn (mut self TFDeployment) load() ! {
	value := self.kvstore.get(self.name)!
	decrypted := self.decrypt(value)!
	decompressed := self.decompress(decrypted)!
	self.decode(decompressed)!
}

fn (mut self TFDeployment) save() ! {
	encoded_data := self.encode()!
	self.kvstore.set(self.name, encoded_data)!
}

fn (self TFDeployment) compress(data []u8) ![]u8 {
	return zlib.compress(data) or { error('Cannot compress the data due to: ${err}') }
}

fn (self TFDeployment) decompress(data []u8) ![]u8 {
	return zlib.decompress(data) or { error('Cannot decompress the data due to: ${err}') }
}

fn (self TFDeployment) encrypt(compressed []u8) ![]u8 {
	key_hashed := sha256.hexhash(self.deployer.mnemonics)
	name_hashed := sha256.hexhash(self.name)
	key := hex.decode(key_hashed)!
	nonce := hex.decode(name_hashed)![..12]
	encrypted := chacha20.encrypt(key, nonce, compressed) or {
		return error('Cannot encrypt the data due to: ${err}')
	}
	return encrypted
}

fn (self TFDeployment) decrypt(data []u8) ![]u8 {
	key_hashed := sha256.hexhash(self.deployer.mnemonics)
	name_hashed := sha256.hexhash(self.name)
	key := hex.decode(key_hashed)!
	nonce := hex.decode(name_hashed)![..12]

	compressed := chacha20.decrypt(key, nonce, data) or {
		return error('Cannot decrypt the data due to: ${err}')
	}
	return compressed
}

fn (self TFDeployment) encode() ![]u8 {
	// TODO: Change to 'encoder'

	data := json.encode(self).bytes()

	compressed := self.compress(data)!
	encrypted := self.encrypt(compressed)!
	return encrypted
}

fn (mut self TFDeployment) decode(data []u8) ! {
	obj := json.decode(TFDeployment, data.bytestr())!
	self.vms = obj.vms
	self.zdbs = obj.zdbs
	self.webnames = obj.webnames
	self.contracts = obj.contracts
	self.network = obj.network
	self.name = obj.name
	self.description = obj.description
}

// Set a new machine on the deployment.
pub fn (mut self TFDeployment) add_machine(requirements VMRequirements) {
	self.vms << VMachine{
		requirements: requirements
	}
}

pub fn (mut self TFDeployment) remove_machine(name string) ! {
	l := self.vms.len
	for id, vm in self.vms {
		if vm.requirements.name == name {
			self.vms[id], self.vms[l - 1] = self.vms[l - 1], self.vms[id]
			self.vms.delete_last()
			return
		}
	}

	return error('vm with name ${name} is not found')
}

// Set a new zdb on the deployment.
pub fn (mut self TFDeployment) add_zdb(zdb ZDBRequirements) {
	self.zdbs << ZDB{
		requirements: zdb
	}
}

pub fn (mut self TFDeployment) remove_zdb(name string) ! {
	l := self.zdbs.len
	for id, zdb in self.zdbs {
		if zdb.requirements.name == name {
			self.zdbs[id], self.zdbs[l - 1] = self.zdbs[l - 1], self.zdbs[id]
			self.zdbs.delete_last()
			return
		}
	}

	return error('zdb with name ${name} is not found')
}

// Set a new webname on the deployment.
pub fn (mut self TFDeployment) add_webname(requirements WebNameRequirements) {
	self.webnames << WebName{
		requirements: requirements
	}
}

pub fn (mut self TFDeployment) remove_webname(name string) ! {
	l := self.webnames.len
	for id, wn in self.webnames {
		if wn.requirements.name == name {
			self.webnames[id], self.webnames[l - 1] = self.webnames[l - 1], self.webnames[id]
			self.webnames.delete_last()
			return
		}
	}

	return error('webname with name ${name} is not found')
}

// lists deployments used with vms, zdbs, and webnames
pub fn (mut self TFDeployment) list_deployments() !map[u32]grid_models.Deployment {
	mut threads := []thread !grid_models.Deployment{}
	mut dls := map[u32]grid_models.Deployment{}
	mut contract_node := map[u64]u32{}
	for node_id, contract_id in self.contracts.node {
		contract_node[contract_id] = node_id.u32()
		threads << spawn self.deployer.get_deployment(contract_id, node_id.u32())
	}

	for th in threads {
		dl := th.wait()!
		node_id := contract_node[dl.contract_id]
		dls[node_id] = dl
	}

	return dls
}

// fn (mut self TFDeployment) vm_delete(vm_name string) ! {
// 	// delete myself, check on TFChain that deletion was indeed done
// 	vm := self.vm_get(vm_name)!

// 	// get all deployments
// 	mut dls := self.list_deployments()!

// 	// load network
// 	mut network_handler := NetworkHandler{
// 		deployer: self.deployer
// 	}

// 	// network_handler.load_network_state(dls)!

// 	// remove vm workload
// 	mut vm_dl := dls[vm.node_id]
// 	mut public_ip_name := ''
// 	for idx, workload in vm_dl.workloads {
// 		if workload.name == vm_name {
// 			zmachine := json.decode(grid_models.Zmachine, workload.data)!
// 			public_ip_name = zmachine.network.public_ip
// 			vm_dl.workloads[idx], vm_dl.workloads[vm_dl.workloads.len - 1] = vm_dl.workloads[vm_dl.workloads.len - 1], vm_dl.workloads[idx]
// 			vm_dl.workloads.delete_last()
// 			break
// 		}
// 	}

// 	for idx, workload in vm_dl.workloads {
// 		if workload.name == public_ip_name {
// 			vm_dl.workloads[idx], vm_dl.workloads[vm_dl.workloads.len - 1] = vm_dl.workloads[vm_dl.workloads.len - 1], vm_dl.workloads[idx]
// 			vm_dl.workloads.delete_last()
// 			break
// 		}
// 	}

// 	// decide if we want to remove the node
// 	if vm_dl.workloads.len == 1 && vm_dl.workloads[0].type_ == grid_models.workload_types.network {
// 		mut ipv4_nodes := 0
// 		for _, endpoint in network_handler.endpoints {
// 			if endpoint.split('.').len == 4 {
// 				ipv4_nodes += 1
// 			}
// 		}

// 		if network_handler.public_node == vm.node_id && (ipv4_nodes > 1
// 			|| network_handler.hidden_nodes.len == 0
// 			|| (network_handler.nodes.len == 2 && network_handler.hidden_nodes.len == 1)
// 			|| (ipv4_nodes == 1 && network_handler.hidden_nodes.len > 0)) {
// 			// we can remove the node
// 			dls.delete(vm.node_id)
// 			network_handler.remove_node(vm.node_id)!
// 		}
// 	}

// 	// use network handler to prepare network
// 	network_workloads := network_handler.generate_workloads(self.dl_versions)!

// 	// replace deloyments network workloads with the ones coming from network handler
// 	for node_id, mut dl in dls {
// 		network_wl := network_workloads[node_id] or { continue }
// 		for id, _ in dl.workloads {
// 			if dl.workloads[id].name == network_wl.name {
// 				dl.workloads[id] = network_wl
// 			}
// 		}
// 	}

// 	// TODO: update deployments
// 	/*
// 		what issues we face:
// 			1. Delete the network workload if not needed
// 			2. Remove the vm node peer from the other deployments if contract is deleted
// 			3. Deploy an access node if the deleted contract was an access node

// 			node1 := dl -> hidden
// 			node2 := dl -> hidden
// 			node3 := dl -> public // will delete it, we need to deploy another access node for node1 and node2

// 			node1 := dl -> public // Assign node1 instead of node3 and delete node1
// 			node2 := dl -> hidden
// 			node3 := dl -> public // will delete it, we need to deploy another access node for node1 and node2
//  	*/
// }
