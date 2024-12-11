module zola

import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.develop.gittools
// import freeflowuniverse.crystallib.osal
// import log
// import os

// TODO: the idea is we can also pull in parts of websites in one mother website e.g. for blogs, just like we do for wiki

// pub struct ZSiteCollection {
// pub mut:
// 	site       &ZolaSite    @[skip; str: skip]
// 	name       string
// 	url        string
// 	reset      bool
// 	pull       bool
// 	gitrepokey string
// 	path       pathlib.Path
// }

// @[params]
// pub struct ZSiteCollectionArgs {
// pub mut:
// 	name string
// 	url  string
// }

// pub fn (mut b ZolaSite) collection_add(args_ ZSiteCollectionArgs) ! {
// 	mut args := args_
// 	mut c := ZSiteCollection{
// 		url: args.url
// 		name: args.name
// 		site: &b
// 	}
// 	b.collections << c
// }

// pub fn (mut self ZSiteCollection) prepare(gs_ gittools.GitStructure, gitrepos_ map[string]gittools.GitRepo) ! {
// 	console.print_header(' zola collection prepare: ${self.url}')
// 	mut gs := gs_
// 	mut locator := gs.locator_new(self.url)!
// 	mut repo := gs.repo_get(locator: locator, reset: false, pull: false)!
// 	mut gitrepos := gitrepos_.clone()
// 	gitrepos[repo.get_key()] = repo
// 	self.gitrepokey = repo.get_key()
// 	self.path = locator.path_on_fs()!
// 	self.path.link('${self.site.path_build.path}/src/${self.name}', true)!
// }
