module tfgrid

import freeflowuniverse.crystallib.core.playbook { Action }
import freeflowuniverse.crystallib.threefold.web3gw.tfgrid as tfgrid_client { DeployVM, RemoveVMFromNetworkDeployment }
import rand

fn (mut t TFGridHandler) vm(action Action) ! {
	match action.name {
		'create' {
			name := action.params.get_default('name', rand.string(6).to_lower())!
			node_id := action.params.get_int_default('node_id', 0)!
			farm_id := action.params.get_int_default('farm_id', 0)!
			flist := action.params.get_default('flist', 'https://hub.grid.tf/tf-official-apps/base:latest.flist')!
			entrypoint := action.params.get_default('entrypoint', '/sbin/zinit init')!
			public_ip := action.params.get_default_false('add_public_ipv4')
			public_ip6 := action.params.get_default_false('add_public_ipv6')
			planetary := action.params.get_default_true('planetary')
			cpu := action.params.get_int_default('cpu', 1)!
			memory := action.params.get_int_default('memory', 1024)!
			rootfs := action.params.get_int_default('rootfs', 2048)!
			gateway := action.params.get_default_false('gateway')
			add_wireguard_access := action.params.get_default_false('add_wireguard_access')
			ssh_key_name := action.params.get_default('sshkey', 'default')!
			ssh_key := t.get_ssh_key(ssh_key_name)!
			env_vars := {
				ssh_key_name: ssh_key
			}
			deploy_res := t.tfgrid.deploy_vm(DeployVM{
				name:                 name
				node_id:              u32(node_id)
				farm_id:              u32(farm_id)
				flist:                flist
				entrypoint:           entrypoint
				public_ip:            public_ip
				public_ip6:           public_ip6
				planetary:            planetary
				cpu:                  u32(cpu)
				memory:               u64(memory)
				rootfs_size:          u64(rootfs)
				env_vars:             env_vars
				add_wireguard_access: add_wireguard_access
				gateway:              gateway
			})!

			t.logger.info('${deploy_res}')
		}
		'get' {
			network := action.params.get('network')!

			get_res := t.tfgrid.get_vm_deployment(network)!

			t.logger.info('${get_res}')
		}
		'remove' {
			network := action.params.get('network')!
			machine := action.params.get('machine')!

			remove_res := t.tfgrid.remove_vm_from_network_deployment(RemoveVMFromNetworkDeployment{
				network: network
				vm:      machine
			})!
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
