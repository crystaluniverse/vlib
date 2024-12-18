module tfgrid

import freeflowuniverse.crystallib.core.playbook { Action }
import freeflowuniverse.crystallib.threefold.web3gw.tfgrid { NetworkConfiguration, VMConfiguration }
import rand

fn (mut t TFGridHandler) network(action Action) ! {
	match action.name {
		'create' {
			name := action.params.get_default('name', rand.string(6).to_lower())!
			description := action.params.get_default('description', '')!
			farm_id := action.params.get_int_default('farm_id', 0)!
			flist := action.params.get_default('flist', '')!
			entrypoint := action.params.get_default('entrypoint', '')!
			public_ip := action.params.get_default_false('public_ip')
			public_ip6 := action.params.get_default_false('public_ip6')
			planetary := action.params.get_default_false('planetary')
			cpu := action.params.get_u32_default('cpu', 1)!
			memory := action.params.get_u64_default('memory', 1024)!
			disk_size := action.params.get_storagecapacity_in_gigabytes('disk_size') or { 0 }
			times := action.params.get_int_default('times', 1)!
			wg := action.params.get_default_false('add_wireguard_access')
			ssh_key_name := action.params.get_default('sshkey', 'default')!
			ssh_key := t.get_ssh_key(ssh_key_name)!

			env_vars := {
				ssh_key_name: ssh_key
			}
			// construct vms from the provided data
			mut vm_configs := []VMConfiguration{}
			for i := 0; i < times; i++ {
				vm_config := VMConfiguration{
					name:        name
					farm_id:     u32(farm_id)
					flist:       flist
					entrypoint:  entrypoint
					public_ip:   public_ip
					public_ip6:  public_ip6
					planetary:   planetary
					cpu:         cpu
					memory:      memory
					rootfs_size: u32(disk_size)
					env_vars:    env_vars
				}
				vm_configs << vm_config
			}
			mut net_config := NetworkConfiguration{
				name:                 name
				add_wireguard_access: wg
			}
			deploy_res := t.tfgrid.deploy_network(
				name:        name
				description: description
				network:     net_config
				vms:         vm_configs
			)!

			t.logger.info('${deploy_res}')
		}
		'get' {
			network := action.params.get('network')!

			get_res := t.tfgrid.get_network_deployment(network)!

			t.logger.info('${get_res}')
		}
		'remove' {
			network := action.params.get('network')!
			machine := action.params.get('machine')!

			remove_res := t.tfgrid.remove_vm_from_network_deployment(
				network: network
				vm:      machine
			)!
			t.logger.info('${remove_res}')
		}
		'delete' {
			network := action.params.get('network')!

			t.tfgrid.cancel_network_deployment(network) or {
				return error('failed to delete vm network: ${err}')
			}
		}
		else {
			return error('operation ${action.name} is not supported on vms')
		}
	}
}
