module lima

import freeflowuniverse.crystallib.installers.virt.lima
import freeflowuniverse.crystallib.ui.console
import virt.lima.raw
import os

@[heap]
pub struct LimaFactory {
pub mut:
	debug bool
}

pub fn new() !LimaFactory {
	lima.install()!
	return LimaFactory{}
}

pub fn (mut lf LimaFactory) vm_get_all() ![]VM {
	mut vms := []VM{}
	for vm in raw.list()! {
		console.print_debug(vm)
		mut vm2 := VM{
			name:           vm.name
			dir:            vm.dir
			arch:           vm.arch
			cpus:           vm.cpus
			memory:         vm.memory / 1000000
			disk:           vm.disk / 1000000
			ssh_local_port: vm.ssh_local_port
			ssh_address:    vm.ssh_address
			identity_file:  vm.identity_file
			factory:        &lf
		}
		match vm.status {
			'Running' {
				vm2.status = .running
			}
			'Stopped' {
				vm2.status = .stopped
			}
			else {
				console.print_debug(vm.status)
				panic('unknown status')
			}
		}
		vms << vm2
	}
	return vms
}

pub fn (mut lf LimaFactory) vm_get(name string) !VM {
	for vm in lf.vm_get_all()! {
		if vm.name.to_lower() == name.to_lower() {
			return vm
		}
	}
	return error("Couldn't find vm with name: ${name}")
}

pub fn (mut lf LimaFactory) vm_exists(name string) !bool {
	for vm in lf.vm_list()! {
		if vm.to_lower() == name.to_lower() {
			return true
		}
	}
	return false
}

pub fn (mut lf LimaFactory) vm_stop_all() ! {
	for mut vm in lf.vm_get_all()! {
		vm.stop()!
	}
}

pub fn (mut lf LimaFactory) vm_delete_all() ! {
	for mut vm in lf.vm_get_all()! {
		vm.delete()!
	}
}

pub fn (mut lf LimaFactory) vm_list() ![]string {
	cmd := "limactl list -f '{{.Name}}'"
	res := os.execute(cmd)
	mut vms := []string{}
	if res.exit_code > 0 {
		return error('could not list lima vm.\n${res}')
	}
	if res.output.contains('No instance found') {
		return []string{}
	}
	for line in res.output.split_into_lines() {
		if line.trim_space() == '' {
			continue
		}
		vms << line.trim_space()
	}
	return vms
}

pub fn (mut lf LimaFactory) vm_stop(name string) ! {
	console.print_header('vm: ${name} stop')
	cmd := 'limactl stop ${name}'
	os.execute(cmd)
	// if res.exit_code > 0 {
	// 	return error('could not delete lima vm.\n${res}')
	// }
	cmd2 := 'limactl stop ${name} -f'
	os.execute(cmd2)
}

pub fn (mut lf LimaFactory) vm_delete(name string) ! {
	console.print_header('vm: ${name} delete')
	lf.vm_stop(name)!
	cmd := 'limactl delete ${name} -f'
	res := os.execute(cmd)
	if res.exit_code > 0 {
		return error('could not delete lima vm.\n${res}')
	}
}
