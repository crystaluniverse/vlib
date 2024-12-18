#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals -cg run

import freeflowuniverse.crystallib.threefold.gridproxy
import freeflowuniverse.crystallib.threefold.tfgrid3deployer
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.installers.threefold.griddriver

fn main() {
	mut installer := griddriver.get()!
	installer.install()!

	// v := tfgrid3deployer.get()!
	// println('cred: ${v}')
	// deployment_name := "my_deployment27"

	// // mut deployment := tfgrid3deployer.new_deployment(deployment_name)!
	// mut deployment := tfgrid3deployer.get_deployment(deployment_name)! 	
	// // deployment.add_machine(name: "my_vm1" cpu: 1 memory: 2 planetary: true mycelium: tfgrid3deployer.Mycelium{}  nodes: [u32(11)])
	// // deployment.add_machine(name: "my_vm3" cpu: 1 memory: 2 planetary: true mycelium: tfgrid3deployer.Mycelium{}  nodes: [u32(11)])
	// // deployment.add_machine(name: "my_vm3" cpu: 1 memory: 2 planetary: true mycelium: tfgrid3deployer.Mycelium{}  nodes: [u32(28)])
	// // deployment.add_zdb(name: "my_zdb", password: "my_passw&rd", size: 2)
	// // deployment.add_webname(name: 'mywebname2', backend: 'http://37.27.132.47:8000')
	// // deployment.deploy()!

	// // deployment.add_machine(name: "my_vm2" cpu: 2 memory: 3 planetary: true mycelium: true  nodes: [u32(28)])
	// // deployment.deploy()!

	// deployment.remove_machine("my_vm1")!
	// // deployment.remove_webname("mywebname2")!
	// // deployment.remove_zdb("my_zdb")!
	// // deployment.deploy()!

	// // deployment.vm_get("my_vm1")!

	// // // deployment.remove_machine(name: "my_vm121")
	// // // deployment.update_machine(name: "my_vm121")
	// println("deployment: ${deployment}")

	// If not sent: The client will create a network for the deployment.
	// deployment.network = NetworkSpecs{
	// 	name:     'hamadanetcafe'
	// 	ip_range: '10.10.0.0/16'
	// }

	// deployment.add_machine(name: "my_vm121" cpu: 1 memory: 2 planetary: true mycelium: true  nodes: [u32(11)])
	// deployment.add_zdb(name: "my_zdb", password: "my_passw&rd", size: 2)
	// deployment.add_webname(name: 'mywebname2', backend: 'http://37.27.132.47:8000')
	// deployment.add_machine(name: "my_vm1" cpu: 1 memory: 2 planetary: true mycelium: true  nodes: [u32(28)])
	// deployment.deploy()!

	// vm1 := deployment.vm_get("my_vm1")!
	// reachable := vm1.healthcheck()!
	// println("vm reachable: ${reachable}")

	// if !reachable {
	// 	deployment.vm_delete()!
	// 	deployment.vm_deploy()!
	// }

	// if !rach {
	// 	vm1.delete()!
	// 	vm1.deploy()!
	// }

	/*
		TODO: Agreed on

		# Deploying a new deployemnt
			mut deployment := tfgrid3deployer.new_deployment(deployment_name)!
			deployment.add_machine(name: "my_vm121" cpu: 1 memory: 2 planetary: true mycelium: true  nodes: [u32(11)])
			deployment.add_zdb(name: "my_zdb", password: "my_passw&rd", size: 2)
			deployment.deploy()!
		
		# if the user wants to load the deployment and do some actions on it:
			mut deployment := tfgrid3deployer.get_deployment(deployment_name)!
			deployment.add_webname(name: 'mywebname2', backend: 'http://37.27.132.47:8000')
			deployment.add_machine(name: "my_vm1" cpu: 1 memory: 2 planetary: true mycelium: true  nodes: [u32(28)])
			deployment.deploy()!

		# The user wants to delete the recently deployed machine
			mut deployment := tfgrid3deployer.get_deployment(deployment_name)!
			deployment.remove_machine(name: "my_vm1")
			deployment.deploy()!

		# The user wants to update the first deployed machine
			mut deployment := tfgrid3deployer.get_deployment(deployment_name)!
			deployment.remove_machine(name: "my_vm1")
			deployment.add_machine(name: "my_vm1" cpu: 1 memory: 2 planetary: true mycelium: true  nodes: [u32(28)])
			deployment.deploy()!
		## PS: The same goes with ZDBs and Webnames

		# How deploy works:
			1. Let's assume the user wants to add one more workload
	*/
}
