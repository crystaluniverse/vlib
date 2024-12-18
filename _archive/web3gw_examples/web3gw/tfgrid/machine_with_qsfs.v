module main

import freeflowuniverse.crystallib.threefold.web3gw.tfgrid

pub struct MachineWithQSFS {
	name                          string
	farm_id                       u32
	cpu                           u32
	memory                        u64
	ssh_key                       string
	public_ipv4                   bool
	rootfs_size                   u64
	description                   string
	cache                         u32
	minimal_shards                u32
	expected_shards               u32
	redundant_groups              u32
	redundant_nodes               u32
	max_zdb_data_dir_size         u32
	encryption_algorithm          string
	encryption_key                string
	compression_algorithm         string
	metadata_type                 string
	metadata_prefix               string
	metadata_encryption_algorithm string
	metadata_encryption_key       string
	zdb_size                      u32 // size in GB
	zdb_password                  string
}

pub struct MachineWithQSFSResult {
pub:
	name                  string
	planetary_ip          string
	ipv4                  string
	qsfs_metrics_endpoint string
}

fn deploy_machine_with_qsfs(mut client tfgrid.TFGridClient, machine_with_qsfs MachineWithQSFS) !MachineWithQSFSResult {
	mut zdbs := []tfgrid.ZDBDeployment{}
	for i in 0 .. machine_with_qsfs.expected_shards {
		zdb_seq := client.deploy_zdb(tfgrid.ZDBDeployment{
			name:     generate_zdb_name(machine_with_qsfs.name, 'seq', i)
			password: machine_with_qsfs.zdb_password
			size:     machine_with_qsfs.zdb_size
			mode:     'seq'
		}) or {
			delete_qsfs_zdbs(mut client, machine_with_qsfs.name, machine_with_qsfs.expected_shards)!
			return error('failed to deploy qsfs zdbs. ${err}')
		}
		zdbs << zdb_seq

		zdb_user := client.deploy_zdb(tfgrid.ZDBDeployment{
			name:     generate_zdb_name(machine_with_qsfs.name, 'user', i)
			password: machine_with_qsfs.zdb_password
			size:     machine_with_qsfs.zdb_size
			mode:     'user'
		}) or {
			delete_qsfs_zdbs(mut client, machine_with_qsfs.name, machine_with_qsfs.expected_shards)!
			return error('failed to deploy qsfs zdbs. ${err}')
		}
		zdbs << zdb_user
	}

	mut groups_backends := []tfgrid.Backend{}
	mut metadata_backends := []tfgrid.Backend{}
	for zdb in zdbs {
		if zdb.mode == 'seq' {
			groups_backends << tfgrid.Backend{
				address:   '[${zdb.ips[1]}]:${zdb.port}'
				namespace: zdb.namespace
				password:  zdb.password
			}
			continue
		}

		if zdb.mode == 'user' {
			metadata_backends << tfgrid.Backend{
				address:   '[${zdb.ips[1]}]:${zdb.port}'
				namespace: zdb.namespace
				password:  zdb.password
			}
		}
	}

	machines_model := client.deploy_vm(tfgrid.DeployVM{
		name:                 machine_with_qsfs.name
		add_wireguard_access: false
		farm_id:              machine_with_qsfs.farm_id
		cpu:                  machine_with_qsfs.cpu
		memory:               machine_with_qsfs.memory
		rootfs_size:          machine_with_qsfs.rootfs_size
		env_vars:             {
			'SSH_KEY': machine_with_qsfs.ssh_key
		}
		public_ip:            machine_with_qsfs.public_ipv4
		planetary:            true
		qsfss:                [
			tfgrid.QSFS{
				mountpoint:            '/qsfs'
				encryption_key:        machine_with_qsfs.encryption_key
				cache:                 machine_with_qsfs.cache
				minimal_shards:        machine_with_qsfs.minimal_shards
				expected_shards:       machine_with_qsfs.expected_shards
				redundant_groups:      machine_with_qsfs.redundant_groups
				redundant_nodes:       machine_with_qsfs.redundant_nodes
				encryption_algorithm:  machine_with_qsfs.encryption_algorithm
				compression_algorithm: machine_with_qsfs.compression_algorithm
				metadata:              tfgrid.Metadata{
					type_:                machine_with_qsfs.metadata_type
					prefix:               machine_with_qsfs.metadata_prefix
					encryption_algorithm: machine_with_qsfs.metadata_encryption_algorithm
					encryption_key:       machine_with_qsfs.encryption_key
					backends:             metadata_backends
				}
				description:           machine_with_qsfs.description
				max_zdb_data_dir_size: machine_with_qsfs.max_zdb_data_dir_size
				groups:                [tfgrid.Group{
					backends: groups_backends
				}]
			},
		]
	}) or {
		client.cancel_vm_deployment(machine_with_qsfs.name)!
		return error('failed to deploy machine: ${err}')
	}

	if machines_model.qsfss.len == 0 {
		delete_machine_with_qsfs(mut client, machine_with_qsfs.name)!
		return error('0 qsfss were found after deployment')
	}

	machine := machines_model
	return MachineWithQSFSResult{
		name:                  machine_with_qsfs.name
		planetary_ip:          machine.planetary_ip
		ipv4:                  machine.computed_ip4
		qsfs_metrics_endpoint: machine.qsfss[0].metrics_endpoint
	}
}

fn delete_qsfs_zdbs(mut client tfgrid.TFGridClient, machine_with_qsfs_name string, count u32) ! {
	for i in 0 .. count {
		client.cancel_zdb_deployment(generate_zdb_name(machine_with_qsfs_name, 'seq',
			i))!
		client.cancel_zdb_deployment(generate_zdb_name(machine_with_qsfs_name, 'user',
			i))!
	}
}

fn delete_machine_with_qsfs(mut client tfgrid.TFGridClient, machine_with_qsfs_name string) ! {
	// the zdbs must be deleted first
	machines_model := client.get_vm_deployment(machine_with_qsfs_name)!

	if machines_model.qsfss.len == 0 {
		return error('no qsfs was found')
	}

	delete_qsfs_zdbs(mut client, machine_with_qsfs_name, machines_model.qsfss[0].expected_shards)!

	client.cancel_vm_deployment(machine_with_qsfs_name)!
}

fn get_machine_with_qsfs(mut client tfgrid.TFGridClient, machine_with_qsfs_name string) !MachineWithQSFSResult {
	machines_model := client.get_vm_deployment(machine_with_qsfs_name)!

	if machines_model.qsfss.len == 0 {
		return error('no qsfs was found')
	}

	machine := machines_model
	return MachineWithQSFSResult{
		name:                  machine_with_qsfs_name
		planetary_ip:          machine.planetary_ip
		ipv4:                  machine.computed_ip4
		qsfs_metrics_endpoint: machine.qsfss[0].metrics_endpoint
	}
}

fn generate_zdb_name(name string, mode string, i u32) string {
	return '${name}${mode}${i}'
}
