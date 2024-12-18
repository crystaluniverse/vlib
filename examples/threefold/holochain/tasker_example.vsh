#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.threefold.tfrobot
import freeflowuniverse.crystallib.ui.console

console.print_header('Tasker Example.')

mut vm := tfrobot.vm_get('holotest', 'test2')!

// get a set of tasks as we want to execute on the vm
mut tasks := vm.tasks_new(name: 'holochain_scaffold')

tasks.step_add(
	nr:      1
	name:    'Verify installation'
	command: 'nix run --refresh -j0 -v github:holochain/holochain#hc-scaffold -- --version'
)!

tasks.step_add(
	nr:      2
	name:    'Create working directory'
	command: 'mkdir -p /root/Holochain'
	depends: '1'
)!

tasks.step_add(
	nr:                3
	name:              'Scaffold application'
	description:       'Scaffold a simple "Hello, World!" Holochain application'
	dir:               '/root/Holochain'
	script:            'nix run github:holochain/holochain#hc-scaffold -- example hello-world || true'
	depends:           '2'
	continue_on_error: true
)!

tasks.step_add(
	nr:      4
	name:    'Run Application'
	dir:     '/root/Holochain/hello-world'
	command: 'nix develop --command bash -c "npm install && npm run start" && exit'
	depends: '3'
)!

vm.tasks_run(tasks)!
vm.tasks_see(tasks)!

vm.vscode_holochain()!

vm.vscode_holochain_proxy()!
