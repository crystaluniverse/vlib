module cloudhypervisor

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.texttools
// import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.installers.ulist
// import freeflowuniverse.crystallib.installers.lang.rust
import os

fn installed() !bool {
	res := os.execute('${osal.profile_path_source_and()} cloud-hypervisor --version')
	if res.exit_code == 0 {
		r := res.output.split_into_lines().filter(it.contains('cloud-hypervisor'))
		if r.len != 1 {
			return error("couldn't parse cloud-hypervisor version, expected 'cloud hypervisor version' on 1 row.\n${res.output}")
		}

		v := texttools.version(r[0].all_after('ypervisor v'))
		// console.print_debug("version: ${v} ${texttools.version(version)}")
		if v != texttools.version(version) {
			return false
		}
	} else {
		return false
	}
	return true
}

fn install() ! {
	console.print_header('install cloudhypervisor')
	// mut installer := get()!
	mut url := ''
	if osal.is_linux_arm() {
		url = 'https://github.com/cloud-hypervisor/cloud-hypervisor/releases/download/v${version0}/cloud-hypervisor-static-aarch64'
	} else if osal.is_linux_intel() {
		url = 'https://github.com/cloud-hypervisor/cloud-hypervisor/releases/download/v${version0}/cloud-hypervisor-static'
	} else {
		return error('unsuported platform for cloudhypervisor')
	}

	osal.package_install('
        qemu-kvm
        bridge-utils
        ovmf
        swtpm
    ')!

	console.print_header('download ${url}')
	dest := osal.download(
		url:        url
		minsize_kb: 1000
		dest:       '/tmp/cloud-hypervisor'
	)!
	console.print_debug('download cloudhypervisor done')
	osal.cmd_add(
		cmdname: 'cloud-hypervisor'
		source:  '${dest.path}'
	)!
}

fn build() ! {
}

// get the Upload List of the files
fn ulist_get() !ulist.UList {
	// mut installer := get()!
	// optionally build a UList which is all paths which are result of building, is then used e.g. in upload
	return ulist.UList{}
}

// uploads to S3 server if configured
fn upload() ! {
	// mut installer := get()!
	// installers.upload(
	//     cmdname: 'cloudhypervisor'
	//     source: '${gitpath}/target/x86_64-unknown-linux-musl/release/cloudhypervisor'
	// )!
}

fn destroy() ! {
	osal.process_kill_recursive(name: 'cloud-hypervisor')!

	osal.package_remove('
       cloudhypervisor
       cloud-hypervisor
    ')!

	// will remove all paths where go/bin is found
	osal.profile_path_add_remove(paths2delete: 'go/bin')!

	cmd := '
        set +e
        find / -name "*.img" -type f -exec rm -f {} \\;
        rm -rf /tmp/cloud-hypervisor*
        rm -f /tmp/cloud-hypervisor.sock
        rm -f /var/log/cloud-hypervisor.log
        umount /mnt/virtiofs
        ip link delete tap0 2>/dev/null
        ip link delete tap1 2>/dev/null
    '

	osal.execute_silent(cmd)!

	osal.rm('
        cloud-hypervisor
        /var/lib/cloud-hypervisor/
    ')!
}
