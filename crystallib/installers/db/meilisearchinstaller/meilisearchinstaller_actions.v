module meilisearchinstaller

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.osal.zinit
import freeflowuniverse.crystallib.installers.ulist
// import freeflowuniverse.crystallib.installers.lang.rust
import os

fn installed() !bool {
	res := os.execute('${osal.profile_path_source_and()} meilisearch -V')
	if res.exit_code != 0 {
		return false
	}
	r := res.output.split_into_lines().filter(it.trim_space().len > 0)
	if r.len != 1 {
		return error("couldn't parse meilisearch version.\n${res.output}")
	}
	r2 := r[0].all_after('meilisearch').trim(' ')
	if texttools.version(version) != texttools.version(r2) {
		return false
	}
	return true
}

fn install() ! {
	console.print_header('install meilisearch')
	mut url := ''

	if osal.is_linux_arm() {
		url = 'https://github.com/meilisearch/meilisearch/releases/download/v${version}/meilisearch-linux-aarch64'
	} else if osal.is_linux_intel() {
		url = 'https://github.com/meilisearch/meilisearch/releases/download/v${version}/meilisearch-linux-amd64'
	} else if osal.is_osx_arm() {
		url = 'https://github.com/meilisearch/meilisearch/releases/download/v${version}/meilisearch-macos-apple-silicon'
	} else if osal.is_osx_intel() {
		url = 'https://github.com/meilisearch/meilisearch/releases/download/v${version}/meilisearch-macos-amd64'
	} else {
		return error('unsported platform')
	}

	mut dest := osal.download(
		url:        url
		minsize_kb: 100000
		expand_dir: '/tmp/meilisearch'
	)!

	// dest.moveup_single_subdir()!

	mut binpath := dest.file_get('meilisearch')!
	osal.cmd_add(
		cmdname: 'meilisearch'
		source:  binpath.path
	)!
}

fn build() ! {
	// mut installer := get()!
	// url := 'https://github.com/threefoldtech/meilisearch'

	// console.print_header('compile meilisearch')
	// rust.install()!
	// mut dest_on_os := '${os.home_dir()}/hero/bin'
	// if osal.is_linux() {
	// 	dest_on_os = '/usr/local/bin'
	// }
	// console.print_debug(' - dest path for meilisearchs is on: ${dest_on_os}')
	// //osal.package_install('pkg-config,openssl')!
	// cmd := '
	// echo "start meilisearch installer"
	// set +ex
	// source ~/.cargo/env > /dev/null 2>&1

	// //TODO

	// cargo install meilisearch

	// cp ${os.home_dir()}/.cargo/bin/mdb* ${dest_on_os}/	
	// '
	// defer {
	//     destroy()!
	// }
	// osal.execute_stdout(cmd)!
	// osal.done_set('install_meilisearch', 'OK')!
	// console.print_header('meilisearch installed')
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
	//     cmdname: 'meilisearch'
	//     source: '${gitpath}/target/x86_64-unknown-linux-musl/release/meilisearch'
	// )!
}

fn startupcmd() ![]zinit.ZProcessNewArgs {
	mut res := []zinit.ZProcessNewArgs{}
	mut installer := get()!
	mut env := 'development'
	if installer.production {
		env = 'production'
	}
	res << zinit.ZProcessNewArgs{
		name: 'meilisearch'
		cmd:  'meilisearch  --no-analytics --http-addr ${installer.host}:${installer.port} --env ${env} --db-path ${installer.path} --master-key ${installer.masterkey}'
	}

	return res
}

fn running() !bool {
	mut installer := get()!
	// THIS IS EXAMPLE CODEAND NEEDS TO BE CHANGED
	// this checks health of meilisearch
	// curl http://localhost:3333/api/v1/s --oauth2-bearer 1234 works
	// url:='http://127.0.0.1:${cfg.port}/api/v1'
	// mut conn := httpconnection.new(name: 'meilisearch', url: url)!

	// if cfg.secret.len > 0 {
	//     conn.default_header.add(.authorization, 'Bearer ${cfg.secret}')
	// }
	// conn.default_header.add(.content_type, 'application/json')
	// console.print_debug("curl -X 'GET' '${url}'/tags --oauth2-bearer ${cfg.secret}")
	// r := conn.get_json_dict(prefix: 'tags', debug: false) or {return false}
	// println(r)
	// if true{panic("ssss")}
	// tags := r['Tags'] or { return false }
	// console.print_debug(tags)
	// console.print_debug('meilisearch is answering.')
	return false
}

fn start_pre() ! {
}

fn start_post() ! {
}

fn stop_pre() ! {
}

fn stop_post() ! {
}

fn destroy() ! {
	// mut systemdfactory := systemd.new()!
	// systemdfactory.destroy("meilisearch")!

	osal.process_kill_recursive(name: 'meilisearch')!

	osal.cmd_delete('meilisearch')!

	osal.package_remove('
       meilisearch
    ') or { println('') }

	// osal.rm("
	// ")!
}
