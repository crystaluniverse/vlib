module gittools

// import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.core.base
import freeflowuniverse.crystallib.ui.console
import os

@[heap]
pub struct GitStructure {
pub mut:
	config   GitStructureConfig // configuration settings
	rootpath pathlib.Path = pathlib.get('${os.home_dir()}/code') // path to root code directory
	repos    []&GitRepo // repositories in gitstructure
	loaded   bool
}

fn (gs GitStructure) cache_key() string {
	return gitstructure_cache_key(gs.name())
}

pub fn (gs GitStructure) name() string {
	return gs.config.name
}

// remove cache
pub fn (gs GitStructure) cache_reset() ! {
	mut c := base.context()!
	mut redis := c.redis()!
	key_check := gs.cache_key()
	keys := redis.keys(key_check + ':*')!
	for key in keys {
		redis.del(key)!
	}
}

pub fn (mut gitstructure GitStructure) list(args ReposGetArgs) ! {
	// texttools.print_clear()
	console.print_debug(' #### overview of repositories:')
	console.print_debug('')
	gitstructure.repos_print(args)!
	console.print_debug('')
}

fn (mut gitstructure GitStructure) repo_from_path(path string) !GitRepo {
	// find parent with .git
	// console.print_debug(" - load from path: $path")
	mypath := pathlib.get_dir(path: path, create: false)!
	mut parentpath := mypath.parent_find('.git') or {
		return error('cannot find .git in parent starting from: ${path}')
	}
	if parentpath.path == '' {
		return error('cannot find .git in parent starting from: ${path}')
	}
	mut ga := GitAddr{
		gsconfig: &gitstructure.config
	}
	mut r := GitRepo{
		gs: &gitstructure
		addr: &ga
		path: parentpath
	}
	r.load_from_path()!
	return r
}

// add repository to gitstructure
pub fn (mut gs GitStructure) repo_add(args GSCodeGetFromUrlArgs) !&GitRepo {
	// console.print_debug('repo_add:${args}')
	if args.path.len > 0 {
		mut repo := gs.repo_from_path(args.path)!
		gs.repo_add_(&repo)!
		return &repo
	}
	mut locator := gs.locator_new(args.url)!
	if args.branch.len > 0 {
		// repo.branch_switch(args.branch)!
		locator.addr.branch = args.branch
	}
	// console.print_debug('got locator ${locator}')
	mut repo := gs.repo_get(locator: locator, reset: false, pull: false)!
	// console.print_debug('got repo ${repo}')
	if args.sshkey.len > 0 {
		repo.ssh_key_set(args.sshkey)!
	}
	if args.reload {
		repo.load()!
	}
	if args.reset {
		repo.remove_changes()!
	}
	if args.pull {
		repo.pull()!
	}
	gs.repo_add_(&repo)!
	return &repo
}

pub struct GSCodeGetFromUrlArgs {
pub mut:
	path   string
	url    string
	branch string
	sshkey string
	pull   bool // will pull if this is set
	reset  bool // this means will pull and reset all changes
	reload bool // reload the cache	
}

// will get repo starting from url, if the repo does not exist, only then will pull .
// if pull is set on true, will then pull as well .
// url examples: .
// ```
// https://github.com/threefoldtech/tfgrid-sdk-ts
// https://github.com/threefoldtech/tfgrid-sdk-ts.git
// git@github.com:threefoldtech/tfgrid-sdk-ts.git
//
// # to specify a branch and a folder in the branch
// https://github.com/threefoldtech/tfgrid-sdk-ts/tree/development/docs
//
// args:
// path   string
// url    string
// branch string
// sshkey string
// pull   bool // will pull if this is set
// reset  bool // this means will pull and reset all changes
// reload bool // reload the cache
// ```
pub fn (mut gs GitStructure) code_get(args_ GSCodeGetFromUrlArgs) !string {
	mut args := args_
	console.print_header('code get url:${args.url} or path:${args.path}')
	mut myrepo := gs.repo_add(args)!
	// console.print_debug(args.str())
	if myrepo.addr.remote_url.len > 0 {
		console.print_debug('repo url ${myrepo.addr.remote_url}')
	} else {
		console.print_debug('repo obj\n${myrepo.addr}')
	}

	if args.reset {
		myrepo.remove_changes()!
	}
	if args.pull || args.reset {
		myrepo.pull()!
	}

	mut locator := gs.locator_new(args.url)!
	// console.print_debug('got locator ${locator}')

	s := locator.path_on_fs()!
	console.print_debug('repo path ${s.path}')

	// osal.exec(
	// 	cmd: 'git checkout ${myrepo.addr.branch}'
	// 	work_folder: s.path
	// )!
	return s.path
}

pub fn (mut gitstructure GitStructure) check() ! {
	mut done := []string{}
	for r in gitstructure.keys() {
		if r in done {
			return error('found double repo with key:${r}')
		}
		done << r
	}
}

fn (mut gs GitStructure) keys() []string {
	mut repokeys := gs.repos.map(it.addr.key())
	return repokeys
}

fn (mut gs GitStructure) repo_add_(repo &GitRepo) ! {
	if repo.key() in gs.keys() {
		return
	}
	gs.repos << repo
}
