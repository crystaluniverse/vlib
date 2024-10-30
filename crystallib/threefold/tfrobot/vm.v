module tfrobot

// import os
import freeflowuniverse.crystallib.builder
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.servers.daguserver as dagu
import freeflowuniverse.crystallib.clients.daguclient as dagu_client
import freeflowuniverse.crystallib.ui.console
import time

// pub fn (vm VMOutput) ssh_interactive(key_path string) ! {
// 	// b := builder.new()
// 	// node := b.node_new(ipaddr:"root@${vm.ip4}")!
// 	// node.exec_interactive('${homedir}/hero/bin/install.sh')!
// 	// time.sleep(15 * time.second)
// 	if vm.public_ip4 != '' {
// 		osal.execute_interactive('ssh -i ${key_path} root@${vm.public_ip4.all_before('/')}')!
// 	} else if vm.yggdrasil_ip != '' {
// 		osal.execute_interactive('ssh -i ${key_path} root@${vm.yggdrasil_ip}')!
// 	} else {
// 		return error('no public nor planetary ip available to use')
// 	}
// }

@[params]
pub struct NodeArgs {
pub mut:
	ip4       bool = true
	ip6       bool = true
	planetary bool = true
	mycelium bool = true
	timeout   int  = 120 // timeout in sec
}

// return ssh node (can be used to do actions remotely)
// will check all available channels till it can ssh into the node
pub fn (vm VMOutput) node(args NodeArgs) !&builder.Node {
	mut b := builder.new()!
	start_time := time.now().unix_milli()
	mut run_time := 0.0
	for true {
		if args.ip4 && vm.public_ip4.len > 0 {
			console.print_debug('test ipv4 to: ${vm.public_ip4} for ${vm.name}')
			if osal.tcp_port_test(address: vm.public_ip4, port: 22, timeout: 2000) {
				console.print_debug('SSH port test ok')
				return b.node_new(
					ipaddr: 'root@${vm.public_ip4}'
					name: '${vm.deployment_name}_${vm.name}'
				)!
			}
		}
		if args.ip6 && vm.public_ip6.len > 0 {
			console.print_debug('test ipv6 to: ${vm.public_ip6} for ${vm.name}')
			if osal.tcp_port_test(address: vm.public_ip6, port: 22, timeout: 2000) {
				console.print_debug('SSH port test ok')
				return b.node_new(
					ipaddr: 'root@[${vm.public_ip6}]'
					name: '${vm.deployment_name}_${vm.name}'
				)!
			}
		}
		if args.planetary && vm.yggdrasil_ip.len > 0 {
			console.print_debug('test planetary to: ${vm.yggdrasil_ip} for ${vm.name}')
			if osal.tcp_port_test(address: vm.yggdrasil_ip, port: 22, timeout: 2000) {
				console.print_debug('SSH port test ok')
				return b.node_new(
					ipaddr: 'root@[${vm.yggdrasil_ip}]'
					name: '${vm.deployment_name}_${vm.name}'
				)!
			}
		}
		run_time = time.now().unix_milli()
		if run_time > start_time + args.timeout * 1000 {
			break
		}
		time.sleep(100 * time.millisecond)
	}
	return error("couldn't connect to node, probably timeout.")
}

pub fn (vm VMOutput) tcpport_addr_get(port int) !string {
	mut b := builder.new()!
	start_time := time.now().unix_milli()
	mut run_time := 0.0
	for true {
		if vm.yggdrasil_ip.len > 0 {
			console.print_debug('test planetary for port ${port}: ${vm.yggdrasil_ip} for ${vm.name}')
			if osal.tcp_port_test(address: vm.yggdrasil_ip, port: port, timeout: 2000) {
				console.print_debug('port test ok')
				return vm.yggdrasil_ip
			}
		}

		// if vm.public_ip4.len>0 {
		// 	console.print_debug("test ipv4 to: ${vm.public_ip4} for ${vm.name}")
		// 	if osal.tcp_port_test(address:vm.public_ip4,port:22, timeout:2000) {
		// 		console.print_debug("SSH port test ok")
		// 		return b.node_new(ipaddr:"root@${vm.public_ip4}",name:"${vm.deployment_name}_${vm.name}")!
		// 	}
		// }
		// if args.ip6 && vm.public_ip6.len>0 {
		// 	console.print_debug("test ipv6 to: ${vm.public_ip6} for ${vm.name}")
		// 	if osal.tcp_port_test(address:vm.public_ip6, port:22, timeout:2000) {				
		// 		console.print_debug("SSH port test ok")
		// 		return b.node_new(ipaddr:"root@[${vm.public_ip6}]",name:"${vm.deployment_name}_${vm.name}")!
		// 	}
		// }
		run_time = time.now().unix_milli()
		if run_time > start_time + 20000 {
			break
		}
		time.sleep(100 * time.millisecond)
	}
	return error("couldn't connect to node, probably timeout.")
}

// // create new DAG
// // ```
// // name                 string // The name of the DAG (required)
// // description          ?string // A brief description of the DAG.
// // tags                 ?string // Free tags that can be used to categorize DAGs, separated by commas.
// // env                  ?map[string]string // Environment variables that can be accessed by the DAG and its steps.
// // restart_wait_sec     ?int          // The number of seconds to wait after the DAG process stops before restarting it.
// // hist_retention_days  ?int          // The number of days to retain execution history (not for log files).
// // delay_sec            ?int          // The interval time in seconds between steps.
// // max_active_runs      ?int          // The maximum number of parallel running steps.
// // max_cleanup_time_sec ?int        // The maximum time to wait after sending a TERM signal to running steps before killing them.
// // ```
// pub fn (mut vm VMOutput) tasks_new(args_ dagu.DAGArgs) &dagu.DAG {
// 	mut args := args_
// 	mut d := dagu.dag_new(
// 		name: args.name
// 		description: args.description
// 		tags: args.tags
// 		env: args.env
// 		restart_wait_sec: args.restart_wait_sec
// 		hist_retention_days: args.hist_retention_days
// 		delay_sec: args.delay_sec
// 		max_active_runs: args.max_active_runs
// 		max_cleanup_time_sec: args.max_cleanup_time_sec
// 	)

// 	d.env = {
// 		'PATH': '/root/.nix-profile/bin:/root/hero/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:\$PATH'
// 	}

// 	return &d
// }

// // name is the name of the tasker (dag), which has set of staps we will execute
// pub fn (vm VMOutput) tasks_run(dag &dagu.DAG) ! {
// 	// console.print_debug(dag)
// 	r := vm.dagu_addr_get()!
// 	console.print_debug('connect to dagu on ${vm.name} -> ${r.addr}')
// 	mut client := dagu_client.get(instance: 'robot_dagu')!
// 	mut cfg := client.config()!
// 	cfg.url = 'http://${r.addr}:${r.port}'
// 	cfg.username = r.username
// 	cfg.password = r.password

// 	if dag.name in client.list_dags()!.dags.map(it.dag.name) {
// 		console.print_debug('delete dag: ${dag.name}')
// 		client.delete_dag(dag.name)!
// 	}

// 	console.print_header('send dag to node: ${dag.name}')
// 	console.print_debug(dag.str())
// 	client.new_dag(dag)! // will post it
// 	client.start_dag(dag.name)!
// }

// pub fn (vm VMOutput) tasks_see(dag &dagu.DAG) ! {
// 	r := vm.dagu_addr_get()!
// 	// http://[302:1d81:cef8:3049:fbe1:69ba:bd8c:52ec]:8081/dags/holochain_scaffold
// 	cmd3 := "open 'http://[${r.addr}]:8081/dags/${dag.name}'"
// 	// console.print_debug(cmd3)
// 	osal.exec(cmd: cmd3)!
// }

pub fn (vm VMOutput) vscode() ! {
	r := vm.dagu_addr_get()!
	cmd3 := "open 'http://[${r.addr}]:8080'"
	// http://[302:1d81:cef8:3049:fbe1:69ba:bd8c:52ec]:8080/?folder=/root/Holochain/hello-world
	// console.print_debug(cmd3)
	osal.exec(cmd: cmd3)!
}

pub fn (vm VMOutput) vscode_holochain() ! {
	r := vm.dagu_addr_get()!
	cmd3 := "open 'http://[${r.addr}]:8080/?folder=/root/Holochain/hello-world'"
	// console.print_debug(cmd3)
	osal.exec(cmd: cmd3)!
}

pub fn (vm VMOutput) vscode_holochain_proxy() ! {
	r := vm.dagu_addr_get()!
	cmd3 := "open 'http://[${r.addr}]:8080/proxy/8282/"
	// console.print_debug(cmd3)
	osal.exec(cmd: cmd3)!
}

struct DaguInfo {
mut:
	addr     string
	username string
	password string
	port     int
}

fn (vm VMOutput) dagu_addr_get() !DaguInfo {
	mut vm_config := vm_config_get(vm.deployment_name, vm.name)!
	mut env := vm_config.env_vars.clone()
	mut r := DaguInfo{}
	r.username = env['DAGU_BASICAUTH_USERNAME'] or { 'admin' }
	r.password = env['DAGU_BASICAUTH_PASSWORD'] or { 'planetfirst' }
	r.port = 8081
	r.addr = vm.tcpport_addr_get(r.port)!
	return r
}
