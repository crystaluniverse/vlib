module podman

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.installers.lang.golang
import freeflowuniverse.crystallib.installers.ulist
import os

// checks if a certain version or above is installed
fn installed() !bool {
	res := os.execute('${osal.profile_path_source_and()} podman -v')
	if res.exit_code != 0 {
		return false
	}
	r := res.output.split_into_lines().filter(it.contains('podman version'))
	if r.len != 1 {
		return error("couldn't parse herocontainers version, expected 'podman version' on 1 row.\n${res.output}")
	}
	v := texttools.version(r[0].all_after('version'))
	if texttools.version(version) == v {
		return true
	}
	return false
}

fn install() ! {
	console.print_header('install podman')

	destroy()!

	mut url := ''
	if osal.platform() == .osx {
		mut dest := '/tmp/podman.pkg'

		if osal.cputype() == .arm {
			url = 'https://github.com/containers/podman/releases/download/v${version}/podman-installer-macos-arm64.pkg'
		} else {
			url = 'https://github.com/containers/podman/releases/download/v${version}/podman-installer-macos-amd64.pkg'
		}

		console.print_header('download ${url}')
		osal.download(
			url:        url
			minsize_kb: 75000
			reset:      true
			dest:       dest
		)!

		cmd := '
		sudo installer -pkg ${dest} -target /
		'
		osal.execute_interactive(cmd)!
		console.print_header(' - pkg installed.')
	} else if osal.platform() == .ubuntu {
		// is the remote tool to connect to a remote podman
		// if osal.cputype() == .arm {
		// 	url = 'https://github.com/containers/podman/releases/download/v${version}/podman-remote-static-linux_arm64.tar.gz'
		// } else {
		// 	url = 'https://github.com/containers/podman/releases/download/v${version}/podman-remote-static-linux_amd64.tar.gz'
		// }
		// console.print_header('download ${url}')
		// dest:=osal.download(
		// 	url: url
		// 	minsize_kb: 75000
		// 	reset: true
		// 	dest: dest
		// )!

		build()!
	} else {
		return error('unsupported platform for podman')
	}
}

fn build() ! {
	// mut installer := get()!

	// https://podman.io/docs/installation#building-from-source

	if osal.platform() != .ubuntu && osal.platform() != .arch {
		return error('only support ubuntu and arch for now')
	}
	mut g := golang.get()!
	g.install()!

	console.print_header('build buildah')

	osal.package_install('btrfs-progs,crun,git,go-md2man,iptables,libassuan-dev,libbtrfs-dev,libc6-dev,libdevmapper-dev,libglib2.0-dev,libgpgme-dev')!
	osal.package_install('libgpg-error-dev,libprotobuf-dev,libprotobuf-c-dev,libseccomp-dev,libselinux1-dev,libsystemd-dev,make,netavark,pkg-config,uidmap')!
	osal.package_install('runc')!

	// conmon
	cmd0 := '
        cd /tmp
        rm -rf conmon
        git clone https://github.com/containers/conmon
        cd conmon
        git checkout v2.1.12
        export GOCACHE="$(mktemp -d)"
        make
        make install

        cd /tmp

        '
	osal.execute_stdout(cmd0)!

	for x in ['conmon'] {
		osal.cmd_add(
			cmdname: x
			source:  '/tmp/conmon/bin/${x}'
		)!
	}

	cmd := '
        cd /tmp
        rm -rf podman
        sudo sysctl kernel.unprivileged_userns_clone=1
        git clone https://github.com/containers/podman
        cd podman
        git checkout v${version}
        export GOCACHE="$(mktemp -d)"

        mkdir -p /etc/containers
        curl -L -o /etc/containers/registries.conf https://raw.githubusercontent.com/containers/image/main/registries.conf
        curl -L -o /etc/containers/policy.json https://raw.githubusercontent.com/containers/image/main/default-policy.json        

        make BUILDTAGS="selinux seccomp" PREFIX=/usr

        '
	osal.execute_stdout(cmd)!

	for x in ['podman', 'podman-remote'] {
		osal.cmd_add(
			cmdname: x
			source:  '/tmp/podman/bin/${x}'
		)!
	}

	osal.rm('
       /tmp/podman
       /tmp/conmon
    ')!
}

// get the Upload List of the files
fn ulist_get() !ulist.UList {
	// mut installer := get()!
	// optionally build a UList which is all paths which are result of building, is then used e.g. in upload

	// /usr/local/bin/conmon
	// /usr/local/bin/podman

	return ulist.UList{}
}

fn destroy() ! {
	osal.package_remove('
       podman
       conmon
       buildah
       skopeo
       runc
    ')!

	// will remove all paths where go/bin is found
	osal.profile_path_add_remove(paths2delete: 'go/bin')!

	osal.rm('
       podman
       conmon
       buildah
       skopeo
       runc
       /var/lib/containers
       /var/lib/podman
       /var/lib/buildah
       /tmp/podman
       /tmp/conmon
    ')!
}
