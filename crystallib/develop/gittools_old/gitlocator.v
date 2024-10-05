module gittools

// import os
// import freeflowuniverse.crystallib.osal.sshagent
import freeflowuniverse.crystallib.core.pathlib
// import freeflowuniverse.crystallib.ui.console

// location of a file, dir or part of file in a GitAddr
@[heap]
pub struct GitLocator {
pub mut:
	addr  &GitAddr
	path  string // path in the repo (not on filesystem)
	anker string // position in the file
}

// will use url to get git locator (is a pointer to a file, dir or part of file)
pub fn (mut gs GitStructure) locator_new(url string) !GitLocator {
	return locator_new(gs.config, url)!
}

// will use url to get git locator (is a pointer to a file, dir or part of file)
pub fn locator_new(gsconfig_ GitStructureConfig, url string) !GitLocator {
	mut gsconfig := gsconfig_
	// console.print_debug(" ** URL: $url **")
	mut urllower := url.to_lower()
	if url.trim_space() == '' {
		$if debug {
			print_backtrace()
		}
		return error('url cannot be empty')
	}
	urllower = urllower.trim_space()
	if urllower.starts_with('ssh://') {
		urllower = urllower[6..]
	}
	if urllower.starts_with('git@') {
		urllower = urllower[4..]
	}
	if urllower.starts_with('http:/') {
		urllower = urllower[6..]
	}
	if urllower.starts_with('https:/') {
		urllower = urllower[7..]
	}
	if urllower.ends_with('.git') {
		urllower = urllower[0..urllower.len - 4]
	}
	urllower = urllower.replace(':', '/')
	urllower = urllower.replace('//', '/')
	urllower = urllower.trim('/')
	urllower = urllower.replace('/blob/', '/')
	urllower = urllower.replace('/src/branch/', '/tree/') // to deal with gitea who has other scheme
	urllower = urllower.replace('/tree/', '/')

	// console.print_debug(" ** URL2: $urllower **")
	// https://github.com/ourworldventures/www_ourworld_tf/tree/development_template/templates
	// https://git.ourworld.tf/drc/info_all4drc/src/branch/main/playbooks/all4drc

	mut parts := urllower.split('/')
	mut anker := ''
	mut path := ''
	mut branch := ''
	// deal with path
	if parts.len > 4 {
		path = parts[4..parts.len].join('/')
		if path.contains('#') {
			parts2 := path.split('#')
			if parts2.len == 2 {
				path = parts2[0]
				anker = parts2[1]
			} else {
				return error("git: url badly formatted have more than 1 x '#' in ${url}")
			}
		}
	}
	// found the branch
	if parts.len > 3 {
		branch = parts[3]
		parts[2] = parts[2].replace('.git', '')
	}
	if parts.len < 3 {
		return error("git:url badly formatted, not enough parts in '${urllower}' \nparts:\n${parts}")
	}

	provider := parts[0]
	account := parts[1]
	name := parts[2]
	mut ga := GitAddr{
		gsconfig: &gsconfig // is reference
		provider: provider
		account: account
		name: name
		branch: branch
		remote_url: url
	}
	// console.print_debug(ga)
	if ga.provider == 'github.com' {
		ga.provider = 'github'
	}
	// ga.provider = ga.provider.replace(".","_")
	mut gl := GitLocator{
		anker: anker
		path: path
		addr: &ga
	}
	// gl.addr.provider = gl.addr.provider.replace(".","_")
	return gl
}

// return the path on the filesystem pointing to the locator
pub fn (mut l GitLocator) path_on_fs() !pathlib.Path {
	addrpath := l.addr.path()!
	if l.path.len > 0 {
		return pathlib.get('${addrpath.path}/${l.path}')
	} else {
		return addrpath
	}
}
