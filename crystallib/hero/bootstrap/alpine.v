module bootstrap

import os
import time
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.ui.console

const iso_path = '/var/vm/alpine-standard-3.19.1-x86_64.iso'
const hdd_path = '/var/vm/vm_alpine_automated.qcow2'
const hostname = 'debug-alpine.vm'

pub struct AlpineLoader {
pub mut:
	alpine_url map[string]string
}

@[params]
pub struct AlpineLoaderArgs {
pub mut:
	alpine_url map[string]string = {
		'aarch64': 'https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/aarch64/alpine-standard-3.19.1-aarch64.iso'
		'x86_64':  'https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/x86_64/alpine-standard-3.19.1-x86_64.iso'
	}
}

pub fn new_alpine_loader(args AlpineLoaderArgs) AlpineLoader {
	mut al := AlpineLoader{
		alpine_url: args.alpine_url
	}
	return al
}

//```
// enum CPUType {
// 	unknown
// 	intel
// 	arm
// 	intel32
// 	arm32
// }
//```
@[params]
pub struct AlpineLaunchArgs {
pub mut:
	name     string
	hostname string       = 'herodev'
	cputype  osal.CPUType = .intel
	reset    bool
}

pub fn (mut self AlpineLoader) start(args_ AlpineLaunchArgs) ! {
	mut args := args_

	mut cpu_name := 'x86_64'
	if args.cputype == .arm {
		cpu_name = 'aarch64'
	}

	if args.name == '' {
		args.name = 'alpine_build_${cpu_name}'
	}

	mut url := self.alpine_url[cpu_name]
	mut iso_path0 := osal.download(
		reset:      args.reset
		url:        url
		minsize_kb: 90000
		dest:       '/tmp/alpine_std_${cpu_name}.iso'
	)!
	iso_path := iso_path0.path

	mut vmdir := pathlib.get_dir(path: '/var/vms/${args.name}', create: true)!
	hdd_path := '${vmdir.path}/hdd.qcow2'
	console.print_debug(' - iso: ${iso_path}')

	// Clean up previous QEMU instance
	console.print_debug('[+] cleaning previous instance of qemu')
	os.system('killall qemu-system-x86_64')
	for os.system('pidof qemu-system-x86_64') == 0 {
		time.sleep(100 * time.millisecond)
	}

	// Check if the ISO file exists
	if !os.exists(iso_path) {
		console.print_debug('ISO file not found: ${iso_path}')
		return
	}

	// Create HDD image if it doesn't exist
	if !os.exists(hdd_path) {
		osal.exec(cmd: 'qemu-img create -f qcow2 ${hdd_path} 10G')!
	}

	// Start the virtual machine
	console.print_debug('[+] starting virtual machine')
	osal.exec(
		cmd: '
        rm -f /tmp/alpine.in
        rm -f /tmp/alpine.out
        mkfifo /tmp/alpine.in /tmp/alpine.out'
	)!
	osal.exec(
		cmd:   '
        qemu-system-x86_64 -m 1024 -cdrom "${iso_path}" -drive file="${hdd_path}",index=0,media=disk,format=qcow2 -boot c -enable-kvm -smp cores=2,maxcpus=2 -net nic -net user,hostfwd=tcp::2225-:22 -virtfs local,path="${SHARED_DIR}",mount_tag="${TAG}",security_model=mapped,id=shared -serial pipe:/tmp/alpine -qmp unix:/tmp/qmp-sock,server,nowait -vnc :0,password=on -monitor stdio
        '
		debug: true
	)!

	// -serial file:/tmp/qemu_log.txt \
	// -display none
	// -daemonize

	console.print_debug('[+] virtual machine started, waiting for console')

	// Interact with the console
	mut console_input := os.open('/tmp/alpine.in') or { panic(err) }
	mut console_output := os.open('/tmp/alpine.out') or { panic(err) }
	defer {
		console_input.close()
		console_output.close()
	}

	for {
		mut line := []u8{len: 1024}
		read_count := console_output.read(mut line) or { break }
		line_str := line[..read_count].bytestr()
		console.print_debug(line_str)
		// Handle console output and send input
		if line_str.contains('localhost login:') {
			console_input.writeln('root')!
		} else if line_str.contains('localhost:~#') {
			console_input.writeln('setup-alpine')!
		} else if line_str.contains(' [localhost]') {
			console_input.writeln(hostname)!
		} else if line_str.contains(' [eth0]') {
			console_input.writeln('')!
		} else if line_str.contains(' [dhcp]') {
			console_input.writeln('')!
		} else if line_str.contains('manual network configuration? (y/n) [n]') {
			console_input.writeln('')!
			console.print_debug('[+] waiting for network connectivity')
		} else if line_str.contains('New password:') {
			console_input.writeln('root')!
		} else if line_str.contains('Retype password:') {
			console_input.writeln('root')!
		} else if line_str.contains('are you in? [UTC]') {
			console_input.writeln('')!
		} else if line_str.contains('HTTP/FTP proxy URL?') && line_str.contains(' [none]') {
			console_input.writeln('')!
		} else if line_str.contains('Enter mirror number or URL: [1]') {
			console_input.writeln('')!
		} else if line_str.contains('Setup a user?') && line_str.contains(' [no]') {
			console_input.writeln('')!
		} else if line_str.contains(' [openssh]') {
			console_input.writeln('')!
		} else if line_str.contains(' [prohibit-password]') {
			console_input.writeln('yes')!
		} else if line_str.contains('Enter ssh key') && line_str.contains(' [none]') {
			console_input.writeln('')!
		} else if line_str.contains('Which disk') && line_str.contains(' [none]') {
			console_input.writeln('sda')!
		} else if line_str.contains('How would you like to use it?') && line_str.contains(' [?]') {
			console_input.writeln('sys')!
		} else if line_str.contains('and continue? (y/n) [n]') {
			console_input.writeln('y')!
		} else if line_str.contains('Installation is complete.') {
			console_input.writeln('reboot')!
		} else if line_str.contains('${hostname} login:') {
			console.print_debug('[+] ====================================================================')
			console.print_debug('[+] virtual machine configured, up and running, root password: root')
			console.print_debug('[+] you can ssh this machine with the local reverse port:')
			console.print_debug('[+]')
			console.print_debug('[+]     ssh root@localhost -p 2225')
			console.print_debug('[+]')
			break
		}
	}

	console.print_debug('[+] virtual machine initialized')
}
