module tfgrid

import freeflowuniverse.crystallib.core.playbook { Action }
import freeflowuniverse.crystallib.threefold.web3gw.tfgrid as tfgrid_client { AddWorkerToK8sCluster, K8sCluster, K8sNode, RemoveWorkerFromK8sCluster }
import rand

fn (mut t TFGridHandler) k8s(action Action) ! {
	match action.name {
		'create' {
			name := action.params.get_default('name', rand.string(8).to_lower())!
			farm_id := action.params.get_int_default('farm_id', 0)!
			capacity := action.params.get_default('capacity', 'small')!
			number_of_workers := action.params.get_int_default('workers', 1)!
			ssh_key_name := action.params.get_default('sshkey', 'default')!
			ssh_key := t.get_ssh_key(ssh_key_name)!
			master_public_ip := action.params.get_default_false('add_public_ip_to_master')
			worerks_public_ip := action.params.get_default_false('add_public_ips_to_workers')
			add_wg_access := action.params.get_default_false('add_wireguard_access')

			cpu, memory, disk_size := get_k8s_capacity(capacity)!

			mut node := K8sNode{
				name:      'master'
				farm_id:   u32(farm_id)
				cpu:       cpu
				memory:    memory
				disk_size: disk_size
				public_ip: master_public_ip
			}

			mut workers := []K8sNode{}
			for _ in 0 .. number_of_workers {
				mut worker := K8sNode{
					name:      'wr' + rand.string(6)
					farm_id:   u32(farm_id)
					cpu:       cpu
					memory:    memory
					disk_size: disk_size
					public_ip: worerks_public_ip
				}

				workers << worker
			}

			cluster := K8sCluster{
				name:          name
				token:         rand.string(6)
				ssh_key:       ssh_key
				master:        node
				workers:       workers
				add_wg_access: add_wg_access
			}

			deploy_res := t.tfgrid.deploy_k8s_cluster(cluster)!

			t.logger.info('${deploy_res}')
		}
		'get' {
			name := action.params.get('name')!

			get_res := t.tfgrid.get_k8s_cluster(name)!

			t.logger.info('${get_res}')
		}
		'add' {
			name := action.params.get('name')!
			farm_id := action.params.get_int_default('farm_id', 0)!
			capacity := action.params.get_default('capacity', 'medium')!
			add_public_ip := action.params.get_default_false('add_public_ip')

			cpu, memory, disk_size := get_k8s_capacity(capacity)!

			mut worker := K8sNode{
				name:      'wr' + rand.string(6)
				farm_id:   u32(farm_id)
				cpu:       cpu
				memory:    memory
				disk_size: disk_size
				public_ip: add_public_ip
			}

			add_res := t.tfgrid.add_worker_to_k8s_cluster(AddWorkerToK8sCluster{
				cluster_name: name
				worker:       worker
			})!

			t.logger.info('${add_res}')
		}
		'remove' {
			name := action.params.get('name')!
			worker_name := action.params.get('worker_name')!

			remove_res := t.tfgrid.remove_worker_from_k8s_cluster(RemoveWorkerFromK8sCluster{
				cluster_name: name
				worker_name:  worker_name
			})!
			t.logger.info('${remove_res}')
		}
		'delete' {
			name := action.params.get('name')!

			t.tfgrid.cancel_k8s_cluster(name) or {
				return error('failed to delete k8s cluster: ${err}')
			}
		}
		else {
			return error('operation ${action.name} is not supported on k8s')
		}
	}
}

fn get_k8s_capacity(capacity string) !(u32, u32, u32) {
	match capacity {
		'small' {
			return 1, 2048, 10
		}
		'medium' {
			return 2, 4096, 20
		}
		'large' {
			return 8, 8192, 40
		}
		'extra-large' {
			return 8, 16384, 100
		}
		else {
			return error('invalid capacity ${capacity}')
		}
	}
}
