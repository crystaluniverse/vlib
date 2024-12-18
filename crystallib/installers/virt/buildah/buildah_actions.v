module buildah

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.installers.ulist
import freeflowuniverse.crystallib.installers.lang.golang
import os

// checks if a certain version or above is installed
fn installed() !bool {
	res := os.execute('${osal.profile_path_source_and()} buildah -v')
	if res.exit_code != 0 {
		return false
	}
	r := res.output.split_into_lines().filter(it.trim_space().len > 0)
	if r.len != 1 {
		return error("couldn't parse herocontainers version, expected 'buildah -v' on 1 row.\n${res.output}")
	}
	v := texttools.version(r[0].all_after('version').all_before('(').replace('-dev', ''))
	if texttools.version(version) == v {
		return true
	}
	return false
}

fn install() ! {
	console.print_header('install buildah')
	build()!
}

fn build() ! {
	console.print_header('build buildah')

	osal.package_install('runc,bats,btrfs-progs,git,go-md2man,libapparmor-dev,libglib2.0-dev,libgpgme11-dev,libseccomp-dev,libselinux1-dev,make,skopeo,libbtrfs-dev')!

	mut g := golang.get()!
	g.install()!

	cmd := '
        cd /tmp
        rm -rf buildah
        git clone https://github.com/containers/buildah
        cd buildah
        make SECURITYTAGS="apparmor seccomp"
        '
	osal.execute_stdout(cmd)!

	// now copy to the default bin path
	osal.cmd_add(
		cmdname: 'buildah'
		source:  '/tmp/buildah/bin/buildah'
	)!

	osal.rm('
       /tmp/buildah
    ')!
}

// get the Upload List of the files
fn ulist_get() !ulist.UList {
	// mut installer := get()!
	// optionally build a UList which is all paths which are result of building, is then used e.g. in upload
	return ulist.UList{}
}

fn destroy() ! {
	osal.package_remove('
       buildah
    ')!

	// will remove all paths where go/bin is found
	osal.profile_path_add_remove(paths2delete: 'go/bin')!

	osal.rm('
       buildah
       /var/lib/buildah
       /tmp/buildah
    ')!
}
