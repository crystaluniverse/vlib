module tfrobot

import freeflowuniverse.crystallib.clients.redisclient
import json
import os
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.osal.sshagent

const tfrobot_dir = '${os.home_dir()}/hero/tfrobot' // path to tfrobot dir in fs

pub struct DeployConfig {
pub mut:
	name        string
	mnemonic    string
	network     Network = .main
	node_groups []NodeGroup       @[required]
	vms         []VMConfig        @[required]
	ssh_keys    map[string]string
	debug       bool
}

pub struct NodeGroup {
	name        string
	nodes_count int    @[required]
	free_cpu    int    @[required] // number of logical cores
	free_mru    int    @[required] // amount of memory in GB
	free_ssd    int  // amount of ssd storage in GB
	free_hdd    int  // amount of hdd storage in GB
	dedicated   bool // are nodes dedicated
	public_ip4  bool
	public_ip6  bool
	certified   bool   // should the nodes be certified(if false the nodes could be certified of diyed)
	region      string // region could be the name of the continents the nodes are located in (africa, americas, antarctic, antarctic ocean, asia, europe, oceania, polar)
}

pub struct VMConfig {
pub mut:
	name        string            @[required]
	vms_count   int = 1               @[required]
	node_group  string
	cpu         int = 4               @[required]
	mem         int = 4               @[required] // in GB
	public_ip4  bool = false
	public_ip6  bool = false
	ygg_ip   bool = true
	mycelium_ip    bool = true
	flist       string            @[required]
	entry_point string            @[required]
	root_size   int = 20
	ssh_key     string
	env_vars    map[string]string
}

// pub struct SSHKey

pub struct DeployResult {
pub:
	ok    map[string][]VMOutput
	error map[string]string
}

pub struct VMOutput {
pub mut:
	name            string  @[json: 'Name'; required]
	network_name            string  @[json: 'NetworkName'; required]
	node_group      string
	deployment_name string
	public_ip4      string  @[json: 'PublicIP4'; required]
	public_ip6      string  @[json: 'PublicIP6'; required]
	yggdrasil_ip    string  @[json: 'YggIP'; required]
	mycelium_ip    string  	@[json: 'MyceliumIP'; required]
	ip              string  @[json: 'IP'; required]
	mounts          []Mount @[json: 'Mounts'; required]
	node_id         u32     @[json: 'NodeID']
	contract_id     u64     @[json: 'ContractID']
}

pub struct Mount {
pub:
	disk_name   string
	mount_point string
}

// get all keys from ssh_agent and add to the config
pub fn sshagent_keys_add(mut config DeployConfig) ! {
	mut ssha := sshagent.new()!
	if ssha.keys.len == 0 {
		return error('no ssh-keys found in ssh-agent, cannot add to tfrobot deploy config.')
	}
	for mut key in ssha.keys_loaded()! {
		config.ssh_keys[key.name] = key.keypub()!.trim('\n')
	}
}

pub fn (mut robot TFRobot[Config]) deploy(config_ DeployConfig) !DeployResult {
	mut config := config_
	cfg := robot.config()!
	if config.mnemonic == '' {
		config.mnemonic = cfg.mnemonics
	}
	config.network = Network.from(cfg.network)!

	if config.ssh_keys.len == 0 {
		return error('no ssh-keys found in config')
	}

	if config.node_groups.len == 0 {
		return error('there are no node requirement groups defined')
	}

	node_group := config.node_groups.first().name

	for mut vm in config.vms {
		if vm.ssh_key.len == 0 {
			vm.ssh_key = config.ssh_keys.keys().first() // first one of the dict
		}
		if vm.ssh_key !in config.ssh_keys {
			return error('Could not find specified sshkey: ${vm.ssh_key} in known sshkeys.\n${config.ssh_keys.values()}')
		}
		if vm.node_group == '' {
			vm.node_group = node_group
		}
	}

	check_deploy_config(config)!

	mut config_file := pathlib.get_file(
		path: '${tfrobot.tfrobot_dir}/deployments/${config.name}_config.json'
		create: true
	)!
	mut output_file := pathlib.get_file(
		path: '${tfrobot.tfrobot_dir}/deployments/${config.name}_output.json'
		create: false
	)!
	config_json := json.encode(config)
	config_file.write(config_json)!
	cmd := 'tfrobot deploy -c ${config_file.path} -o ${output_file.path}'
	if config.debug {
		console.print_debug(config.str())
		console.print_debug(cmd)
	}
	_ := osal.exec(
		cmd: cmd
		stdout: true
	) or {return error('TFRobot command ${cmd} failed:\n${err}')}
	output := output_file.read()!
	mut res := json.decode(DeployResult, output)!

	if res.ok.len == 0 {
		return error('No vm was deployed, empty result')
	}

	mut redis := redisclient.core_get()!

	redis.hset('tfrobot:${config.name}', 'config', config_json)!
	for groupname, mut vms in res.ok {
		for mut vm in vms {
			if config.debug {
				console.print_header('vm deployed: ${vm.name}')
				console.print_debug(vm.str())
			}
			vm.node_group = groupname // remember the groupname
			vm.deployment_name = config.name
			vm_json := json.encode(vm)
			redis.hset('tfrobot:${config.name}', vm.name, vm_json)!
		}
	}
	return res
}

fn check_deploy_config(config DeployConfig) ! {
	// Checking if configuration is valid. For instance that there is no ssh_key key that isnt defined,
	// or that the specified node group of a vm configuration exists
	vms := config.vms.filter(it.node_group !in config.node_groups.map(it.name))
	if vms.len > 0 {
		error_msgs := vms.map('Node group: `${it.node_group}` for VM: `${it.name}`')
		return error('${error_msgs.join(',')} not found.')
	}

	unknown_keys := config.vms.filter(it.ssh_key !in config.ssh_keys).map(it.ssh_key)
	if unknown_keys.len > 0 {
		return error('SSH Keys [${unknown_keys.join(',')}] not found.')
	}
}
