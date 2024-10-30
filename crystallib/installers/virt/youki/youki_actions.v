module youki

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.develop.gittools

import freeflowuniverse.crystallib.installers.ulist
import freeflowuniverse.crystallib.installers.lang.golang
import freeflowuniverse.crystallib.installers.lang.rust
import freeflowuniverse.crystallib.installers.lang.python

import os


// checks if a certain version or above is installed
fn installed() !bool {
    //THIS IS EXAMPLE CODEAND NEEDS TO BE CHANGED
    // res := os.execute('${osal.profile_path_source_and()} youki version')
    // if res.exit_code != 0 {
    //     return false
    // }
    // r := res.output.split_into_lines().filter(it.trim_space().len > 0)
    // if r.len != 1 {
    //     return error("couldn't parse youki version.\n${res.output}")
    // }
    // if texttools.version(version) > texttools.version(r[0]) {
    //     return false
    // }
    return false
}

fn install() ! {
    console.print_header('install youki')
    destroy()!
    build()!
}

fn build() ! {
    //mut installer := get()!
    url := 'https://github.com/containers/youki'

    rust.install()!

    console.print_header('build youki')

    //, tag:'v0.4.1'
    mut gs := gittools.new(coderoot: '/tmp/youki')!
	mut repo := gs.get_repo(
		url: url
		reset: true
		pull: true
	)!

	mut gitpath := repo.get_path()!

    cmd := '
    cd ${gitpath}
    source ~/.cargo/env
    bash scripts/build.sh -o /tmp/youki/build -r -c youki
    '
    osal.execute_stdout(cmd)!
    
    osal.cmd_add(
        cmdname: 'youki'
        source: '/tmp/youki/build/youki'
    )!   

}

//get the Upload List of the files
fn ulist_get() !ulist.UList {
    //mut installer := get()!
    //optionally build a UList which is all paths which are result of building, is then used e.g. in upload
    return ulist.UList{}
}

//uploads to S3 server if configured
fn upload() ! {
    //mut installer := get()!
    // installers.upload(
    //     cmdname: 'youki'
    //     source: '${gitpath}/target/x86_64-unknown-linux-musl/release/youki'
    // )!

}



fn destroy() ! {

    osal.package_remove('
       runc
    ')!

    osal.rm("
       youki
    ")!


}

