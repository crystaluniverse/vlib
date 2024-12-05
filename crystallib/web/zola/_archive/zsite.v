module zola

import freeflowuniverse.crystallib.ui.console
// import freeflowuniverse.crystallib.osal
// import os
// import freeflowuniverse.crystallib.develop.gittools
import freeflowuniverse.crystallib.core.pathlib
import os

// @[heap]
// pub struct ZSite {
// pub mut:
// 	zola         &Zola             @[skip; str: skip]
// 	url          string // url of site repo
// 	name         string
// 	path_build   pathlib.Path
// 	path_publish pathlib.Path
// 	collections  []ZSiteCollection
// 	gitrepokey   string
// 	tailwindcss  bool // whether site uses tailwindcss
// }

// @[params]
// pub struct ZSiteArgs {
// pub mut:
// 	name string @[required]
// 	// url  string @[required] // url of the summary.md file
// 	pull bool
// }

//////////

// // pub fn (mut sites Zola) site_new(args ZSiteArgs) !&ZolaSite {
// 	path_build := '${sites.path_build}/${args.name}'
// 	path_publish := '${sites.path_publish}/${args.name}'

// 	mut site := ZolaSite{
// 		name: args.name
// 		// url: args.url
// 		path_build: pathlib.get_dir(path: path_build, create: true)!
// 		path_publish: pathlib.get_dir(path: path_publish, create: true)!
// 	}
// 	sites.sites << &site

// 	// mut gs := sites.gitstructure
// 	// mut locator := gs.locator_new(args.url)!
// 	// mut repo := gs.repo_get(locator: locator, reset: false, pull: false)!
// 	// sites.gitrepos[repo.get_key()] = repo
// 	// site.gitrepokey = repo.get_key()
// 	// mut path_site_dir := locator.path_on_fs()!

// 	return &site
// }

pub fn (mut self ZSite) prepare() ! {
	// os.mkdir_all('${site.path_build.path}/src')!
}

pub fn (mut site ZSite) generate() ! {
	if site.changed() == false {
		return
	}
	console.print_header(' site generate: ${site.name} on ${site.path_build.path}')
	console.print_debug('bash ${site.path_build.path}/build.sh')
	// TODO: should not be the build, it should be the native command without the build script
	os.execute('bash ${site.path_build.path}/build.sh')
	os.mv('${site.path_build.path}/public', site.path_publish.path)!
}

// all the gitrepo keys
fn (mut site ZSite) gitrepo_keys() []string {
	mut res := []string{}
	res << site.gitrepokey
	for collection in site.collections {
		if collection.gitrepokey !in res {
			res << collection.gitrepokey
		}
	}
	return res
}

// is there change in repo since last build?
fn (mut site ZSite) changed() bool {
	mut change := false
	gitrepokeys := site.gitrepo_keys()
	for key, status in site.zola.gitrepos_status {
		if key in gitrepokeys {
			// means this site is using that gitrepo, so if it changed the site changed
			if status.revlast != status.revlast {
				change = true
			}
		}
	}
	return change
}
