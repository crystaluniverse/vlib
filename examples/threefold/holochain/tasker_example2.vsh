#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.threefold.tfrobot
import freeflowuniverse.crystallib.ui.console

console.print_header('Tasker Example 2.')

mut vm := tfrobot.vm_get('holotest', 'test1')!

// get a set of tasks as we want to execute on the vm
mut tasks := vm.tasks_new(name: 'sysadmin')

tasks.step_add(
	nr:      1
	name:    'ls'
	command: 'ls /'
)!

tasks.step_add(
	nr:      2
	name:    'install something'
	command: 'nix-env --install mc'
	depends: '1'
)!

vm.tasks_run(tasks)!
vm.tasks_see(tasks)!
