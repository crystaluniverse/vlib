module gittools

import freeflowuniverse.crystallib.osal.sshagent
import freeflowuniverse.crystallib.core.pathlib

// unique identification of a git repository
// can be translated to location on filesystem
// can be translated to url of the git repository online
@[heap]
pub struct GitAddr {
pub mut:
	gsconfig   &GitStructureConfig
	provider   string
	account    string
	name       string // is the name of the repository
	branch     string
	remote_url string
}

// internal function to check git address
fn (addr GitAddr) check() {
	if addr.provider == '' || addr.account == '' || addr.name == '' {
		panic('provider, account or name is empty: ${addr.provider}/${addr.account}/${addr.name}')
	}
}

// return the path on the filesystem pointing to the address (is always a dir)
pub fn (addr GitAddr) path() !pathlib.Path {
	addr.check()
	// provider := texttools.name_fix(addr.provider)
	// name := texttools.name_fix(addr.name)
	// account := texttools.name_fix(addr.account)
	mut path_string := '${addr.gsconfig.root}/${addr.provider}/${addr.account}/${addr.name}'
	if addr.gsconfig.singlelayer {
		path_string = '${addr.gsconfig.root}/${addr.name}'
	}
	if addr.gsconfig.root == '' {
		panic('rootpath cannot be empty\n${addr}')
	}
	if addr.gsconfig.multibranch {
		path_string += '/${addr.branch}'
	}
	path := pathlib.get_dir(
		path: path_string
		check: false
	)!
	return path
}

pub fn (addr GitAddr) key() string {
	return '${addr.provider}:${addr.account}:${addr.name}:${addr.branch}'
}

fn (addr GitAddr) path_account() pathlib.Path {
	addr.check()
	if addr.gsconfig.root == '' {
		panic('cannot be empty')
	}
	mut path_string := '${addr.gsconfig.root}/${addr.provider}/${addr.account}'
	if addr.gsconfig.singlelayer {
		path_string = '${addr.gsconfig.root}'
	}
	path := pathlib.get_dir(
		path: path_string
		create: true
	) or { panic('couldnt get directory') }
	return path
}

// url_get returns the url of a git address
pub fn (addr GitAddr) url_get() string {
	if sshagent.loaded() {
		return addr.url_ssh_get()
	} else {
		return addr.url_http_get()
	}
}

pub fn (addr GitAddr) url_ssh_get() string {
	addr.check()
	mut provider := addr.provider
	if provider == 'github' {
		provider = 'github.com'
	}
	return 'git@${provider}:${addr.account}/${addr.name}.git'
}

pub fn (addr GitAddr) url_http_get() string {
	addr.check()
	mut provider := addr.provider
	if provider == 'github' {
		provider = 'github.com'
	}
	return 'https://${provider}/${addr.account}/${addr.name}'
}

// return http url with branch inside
fn (addr GitAddr) url_http_with_branch_get() string {
	addr.check()
	u := addr.url_http_get()
	if addr.branch != '' {
		return '${u}/tree/${addr.branch}'
	} else {
		return u
	}
}

pub fn (addr GitAddr) str() string {
	return '${addr.provider}:${addr.account}/${addr.name}[${addr.branch}]'
}

// CACHE ARGS

fn (addr GitAddr) cache_key_status() string {
	cache_key := gitstructure_cache_key(addr.gsconfig.name)
	return '${cache_key}:${addr.cache_key_provider_account_name()}'
}

fn (addr GitAddr) cache_key_path(path string) string {
	cache_key := gitstructure_cache_key(addr.gsconfig.name)
	return '${cache_key}:${path}'
}

fn (addr GitAddr) cache_key_provider_account_name() string {
	addr.check()
	return '${addr.provider}__${addr.account}__${addr.name}'
}
