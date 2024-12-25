module golang

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.installers.base
import freeflowuniverse.crystallib.installers.ulist
import os

// checks if a certain version or above is installed
fn installed() !bool {
	res := os.execute('${osal.profile_path_source_and()} go version')
	if res.exit_code == 0 {
		r := res.output.split_into_lines()
			.filter(it.contains('go version'))

		if r.len != 1 {
			return error("couldn't parse go version, expected 'go version' on 1 row.\n${res.output}")
		}

		mut vstring := r[0] or { panic('bug') }

		vstring = vstring.all_after_first('version').all_after_first('go').all_before(' ').trim_space()
		v := texttools.version(vstring)
		if v == texttools.version(version) {
			return true
		}
	}
	return false
}

fn install() ! {
	console.print_header('install golang')
	base.install()!
	destroy()!

	mut url := ''
	if osal.is_linux_arm() {
		url = 'https://go.dev/dl/go${version}.limux-arm64.tar.gz'
	} else if osal.is_linux_intel() {
		url = 'https://go.dev/dl/go${version}.linux-amd64.tar.gz'
	} else if osal.is_osx_arm() {
		url = 'https://go.dev/dl/go${version}.darwin-arm64.tar.gz'
	} else if osal.is_osx_intel() {
		url = 'https://go.dev/dl/go${version}.darwin-amd64.tar.gz'
	} else {
		return error('unsupported platform')
	}

	expand_dir := '/tmp/golang'

	// the downloader is cool, it will check the download succeeds and also check the minimum size
	_ = osal.download(
		url: url
		minsize_kb: 40000
		expand_dir: expand_dir
	)!

	go_dest := '${osal.usr_local_path()!}/go'
	os.mv('${expand_dir}/go', go_dest)!
	os.rmdir_all(expand_dir)!
	osal.profile_path_add_remove(paths2add: '${go_dest}/bin')!
}

fn build() ! {
}

// get the Upload List of the files
fn ulist_get() !ulist.UList {
	// mut installer := get()!
	// optionally build a UList which is all paths which are result of building, is then used e.g. in upload
	return ulist.UList{}
}

fn destroy() ! {
	console.print_debug('golang destroy')

	osal.package_remove('golang')!

	// will remove all paths where go/bin is found
	osal.profile_path_add_remove(paths2delete: 'go/bin')!

	osal.rm('
        #next will find go as a binary and remove, is like cmd delete
        go
        /usr/local/go
        /root/hero/bin/go
        ~/.go
        ~/go
    ')!
}

pub fn install_reset() ! {
	mut installer := get()!

	// will automatically do a destroy if the version changes, to make sure there are no left overs
	installer.install()!
}
