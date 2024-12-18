module main

import freeflowuniverse.crystallib.threefold.web3gw.tfgrid { K8sCluster, K8sNode, TFGridClient }
import log { Logger }
import flag { FlagParser }
import os
import freeflowuniverse.crystallib.data.rpcwebsocket
import rand

const default_server_address = 'ws://127.0.0.1:8080'

fn deploy_k8s(mut fp FlagParser, mut t TFGridClient) !K8sCluster {
	fp.usage_example('deploy [options]')

	name := fp.string_opt('name', `n`, 'Name of the cluster')!
	token := fp.string('token', `t`, rand.string(20), 'Token for the cluster, used to let workers join the cluster')
	ssh_key := fp.string_opt('ssh_key', `s`, 'Public SSH Key to access any cluster node')!
	number_of_workers := fp.int('workers', `w`, 1, 'Number of workers to add to the cluster')
	farm_id := fp.int('farm_id', `f`, 0, 'Farm ID to deploy on')
	capacity := fp.string('capacity', `c`, 'medium', 'Capacity of the cluster nodes')
	public_ip := fp.bool('public_ip', `i`, false, 'True to add public ips for each cluster node')
	_ := fp.finalize()!

	cpu, memory, disk_size := get_k8s_capacity(capacity)!

	mut workers := []K8sNode{}
	for i in 0 .. number_of_workers {
		mut worker := K8sNode{
			name:      'wr${i}'
			farm_id:   u32(farm_id)
			cpu:       cpu
			memory:    memory
			disk_size: disk_size
			public_ip: public_ip
		}

		workers << worker
	}

	cluster := K8sCluster{
		name:    name
		token:   token
		ssh_key: ssh_key
		master:  K8sNode{
			name:      'master'
			farm_id:   u32(farm_id)
			cpu:       cpu
			memory:    memory
			disk_size: disk_size
			public_ip: public_ip
		}
		workers: workers
	}

	return t.deploy_k8s_cluster(cluster)!
}

fn get_k8s(mut fp FlagParser, mut t TFGridClient) !K8sCluster {
	fp.usage_example('get [options]')

	name := fp.string_opt('name', `n`, 'Name of the clusetr')!
	_ := fp.finalize()!

	return t.get_k8s_cluster(name)!
}

fn delete_k8s(mut fp FlagParser, mut t TFGridClient) ! {
	fp.usage_example('delete [options]')

	name := fp.string_opt('name', `n`, 'Name of the cluster')!
	_ := fp.finalize()!

	return t.cancel_k8s_cluster(name)
}

fn add_k8s_worker(mut fp FlagParser, mut t TFGridClient) !K8sCluster {
	fp.usage_example('add [options]')

	name := fp.string_opt('name', `n`, 'Name of the cluster')!
	farm_id := fp.int('farm_id', `f`, 0, 'Farm ID to deploy on')
	capacity := fp.string('capacity', `c`, 'medium', 'Capacity of the cluster nodes')
	public_ip := fp.bool('public_ip', `i`, false, 'True to add public ips for each cluster node')
	_ := fp.finalize()!

	cpu, memory, disk_size := get_k8s_capacity(capacity)!

	worker := K8sNode{
		name:      'wr' + rand.string(6)
		farm_id:   u32(farm_id)
		cpu:       cpu
		memory:    memory
		disk_size: disk_size
		public_ip: public_ip
	}

	return t.add_worker_to_k8s_cluster(
		cluster_name: name
		worker:       worker
	)!
}

fn remove_k8s_worker(mut fp FlagParser, mut t TFGridClient) !K8sCluster {
	fp.usage_example('remove [options]')

	name := fp.string_opt('name', `n`, 'Name of the clusetr')!
	worker_name := fp.string_opt('worker_name', `w`, 'Name of the worker to remove')!
	_ := fp.finalize()!

	return t.remove_worker_from_k8s_cluster(
		cluster_name: name
		worker_name:  worker_name
	)!
}

fn main() {
	mut fp := flag.new_flag_parser(os.args)
	fp.application('Welcome to the web3_proxy client. The web3_proxy client allows you to execute all remote procedure calls that the web3_proxy server can handle.')
	fp.description('')
	fp.skip_executable()
	fp.allow_unknown_args()

	mnemonic := fp.string_opt('mnemonic', `m`, 'The mnemonic to be used to call any function') or {
		eprintln('${err}')
		exit(1)
	}
	network := fp.string('network', `n`, 'dev', 'TF network to use')
	address := fp.string('address', `a`, '${default_server_address}', 'The address of the web3_proxy server to connect to.')
	debug_log := fp.bool('debug', 0, false, 'By setting this flag the client will print debug logs too.')
	operation := fp.string_opt('operation', `o`, 'Required operation to perform ')!
	remainig_args := fp.finalize() or {
		eprintln('${err}')
		exit(1)
	}

	mut logger := Logger(&log.Log{
		level: if debug_log { .debug } else { .info }
	})

	mut myclient := rpcwebsocket.new_rpcwsclient(address, &logger) or {
		logger.error('Failed creating rpc websocket client: ${err}')
		exit(1)
	}

	_ := spawn myclient.run()

	mut tfgrid_client := tfgrid.new(mut myclient)

	tfgrid_client.load(tfgrid.Load{
		mnemonic: mnemonic
		network:  network
	})!

	match operation {
		'deploy' {
			mut new_fp := flag.new_flag_parser(remainig_args)
			res := deploy_k8s(mut new_fp, mut tfgrid_client) or {
				logger.error('${err}')
				exit(1)
			}
			logger.info('${res}')
		}
		'get' {
			mut new_fp := flag.new_flag_parser(remainig_args)
			res := get_k8s(mut new_fp, mut tfgrid_client) or {
				logger.error('${err}')
				exit(1)
			}
			logger.info('${res}')
		}
		'delete' {
			mut new_fp := flag.new_flag_parser(remainig_args)
			delete_k8s(mut new_fp, mut tfgrid_client) or {
				logger.error('${err}')
				exit(1)
			}
		}
		'add' {
			mut new_fp := flag.new_flag_parser(remainig_args)
			add_k8s_worker(mut new_fp, mut tfgrid_client) or {
				logger.error('${err}')
				exit(1)
			}
		}
		'remove' {
			mut new_fp := flag.new_flag_parser(remainig_args)
			remove_k8s_worker(mut new_fp, mut tfgrid_client) or {
				logger.error('${err}')
				exit(1)
			}
		}
		else {
			logger.error('operation ${operation} is invalid')
			exit(1)
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
