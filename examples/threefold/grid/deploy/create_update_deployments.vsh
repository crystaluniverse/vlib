#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.threefold.grid.models
import freeflowuniverse.crystallib.threefold.grid as tfgrid
import json
import log

const pubkey = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDTwULSsUubOq3VPWL6cdrDvexDmjfznGydFPyaNcn7gAL9lRxwFbCDPMj7MbhNSpxxHV2+/iJPQOTVJu4oc1N7bPP3gBCnF51rPrhTpGCt5pBbTzeyNweanhedkKDsCO2mIEh/92Od5Hg512dX4j7Zw6ipRWYSaepapfyoRnNSriW/s3DH/uewezVtL5EuypMdfNngV/u2KZYWoeiwhrY/yEUykQVUwDysW/xUJNP5o+KSTAvNSJatr3FbuCFuCjBSvageOLHePTeUwu6qjqe+Xs4piF1ByO/6cOJ8bt5Vcx0bAtI8/MPApplUU/JWevsPNApvnA/ntffI+u8DCwgP'

fn test_create_and_update_deployment() ! {
	mut logger := &log.Log{}
	logger.set_level(.debug)
	mnemonics := tfgrid.get_mnemonics()!
	mut deployer := tfgrid.new_deployer(mnemonics, .dev, mut logger)!
	node_privkey := deployer.client.generate_wg_priv_key()!
	user_privkey := deployer.client.generate_wg_priv_key()!
	twin_id := deployer.client.get_user_twin()!
	println('your wireguard privatekey is ${user_privkey[0]}')
	mut network := models.Znet{
		ip_range:              '10.1.0.0/16'
		subnet:                '10.1.1.0/24'
		wireguard_private_key: node_privkey[0] // node private key
		wireguard_listen_port: 3012
		peers:                 [
			models.Peer{
				subnet:               '10.1.2.0/24'
				wireguard_public_key: user_privkey[1] // user public key
				allowed_ips:          ['10.1.2.0/24', '100.64.1.2/32']
			},
		]
	}
	mut znet_workload := models.Workload{
		version:     0
		name:        'networkaa'
		type_:       models.workload_types.network
		data:        json.encode_pretty(network)
		description: 'test network2'
	}

	disk_name := 'mydisk'
	zmount := models.Zmount{
		size: 2 * 1024 * 1024 * 1024
	}
	zmount_workload := zmount.to_workload(name: disk_name)

	mount := models.Mount{
		name:       disk_name
		mountpoint: '/disk1'
	}

	public_ip_name := 'mypubip'
	ip := models.PublicIP{
		v4: true
	}
	ip_workload := ip.to_workload(name: public_ip_name)

	zmachine := models.Zmachine{
		flist:            'https://hub.grid.tf/tf-official-apps/base:latest.flist'
		entrypoint:       '/sbin/zinit init'
		network:          models.ZmachineNetwork{
			public_ip:  public_ip_name
			interfaces: [
				models.ZNetworkInterface{
					network: 'networkaa'
					ip:      '10.1.1.3'
				},
			]
			planetary:  true
		}
		compute_capacity: models.ComputeCapacity{
			cpu:    1
			memory: i64(1024) * 1024 * 1024 * 2
		}
		env:              {
			'SSH_KEY': pubkey
		}
		mounts:           [mount]
	}

	mut zmachine_workload := models.Workload{
		version:     0
		name:        'vm2'
		type_:       models.workload_types.zmachine
		data:        json.encode(zmachine)
		description: 'zmachine test'
	}

	zlogs := models.ZLogs{
		zmachine: 'vm2'
		output:   'wss://example_ip.com:9000'
	}
	zlogs_workload := zlogs.to_workload(name: 'myzlogswl')

	zdb := models.Zdb{
		size: 2 * 1024 * 1024
		mode: 'seq'
	}
	zdb_workload := zdb.to_workload(name: 'myzdb')

	mut deployment := models.Deployment{
		version:               0
		twin_id:               twin_id
		description:           'zm kjasdf1nafvbeaf1234t21'
		workloads:             [znet_workload, zmount_workload, zmachine_workload, zlogs_workload,
			zdb_workload, ip_workload]
		signature_requirement: models.SignatureRequirement{
			weight_required: 1
			requests:        [
				models.SignatureRequest{
					twin_id: twin_id
					weight:  1
				},
			]
		}
	}

	deployment.add_metadata('myproject', 'hamada')
	node_id := u32(14)
	solution_provider := u64(0)

	contract_id := deployer.deploy(node_id, mut deployment, deployment.metadata, solution_provider)!
	deployer.logger.info('created contract id ${contract_id}')

	res_deployment := deployer.get_deployment(contract_id, node_id)!

	mut zmachine_planetary_ip := ''
	for wl in res_deployment.workloads {
		if wl.name == zmachine_workload.name {
			res := json.decode(models.ZmachineResult, wl.result.data)!
			zmachine_planetary_ip = res.planetary_ip
			break
		}
	}

	gw_name := models.GatewayNameProxy{
		name:     'mygwname1'
		backends: ['http://[${zmachine_planetary_ip}]:9000']
	}
	gw_name_wl := gw_name.to_workload(name: 'mygwname1')

	name_contract_id := deployer.client.create_name_contract('mygwname1')!
	deployer.logger.info('name contract id: ${name_contract_id}')

	deployment.workloads << gw_name_wl
	deployer.update_deployment(node_id, mut deployment, deployment.metadata)!
}

fn main() {
	test_create_and_update_deployment() or { println('error happened: ${err}') }
}
