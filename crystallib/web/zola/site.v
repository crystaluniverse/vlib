module zola

import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.data.doctree
import freeflowuniverse.crystallib.develop.gittools
// import freeflowuniverse.crystallib.data.markdownparser
// import freeflowuniverse.crystallib.data.markdownparser.elements
import os
import freeflowuniverse.crystallib.core.texttools

pub struct Template {
	url string
}

@[heap]
pub struct ZolaSite {
pub mut:
	name         string
	url          string       @[required] // base url of site
	title        string
	description  string
	path_build   pathlib.Path
	path_publish pathlib.Path
	// zola         &Zola              @[skip; str: skip]
	tree      doctree.Tree       @[skip; str: skip]
	pages     []ZolaPage
	header    ?Header
	footer    ?Footer
	blog      Blog
	people    ?People
	news      ?News
	sections  map[string]Section
	templates []Template
}

@[params]
pub struct ZolaSiteArgs {
pub mut:
	name         string @[required]
	title        string
	description  string
	path_publish string // optional
	url          string = 'http://localhost:9998/' // base url of site
}

// add template
//```args for getting the template
// path   string
// url    string
// branch string
// sshkey string
// pull   bool // will pull if this is set
// reset  bool // this means will pull and reset all changes
// reload bool // reload the cache
//```
pub fn (mut site ZolaSite) template_add(args gittools.ReposGetArgs) ! {
	mut gs := gittools.get()!
	
	mypath := gs.get_repo(args)!
	for i in ['css', 'static', 'templates'] {
		os.cp_all('${mypath}/${i}', '${site.path_build.path}/${i}', true)!
	}
}

// add content from website, can be more than 1, will sync but not overwrite to the destination website
//```args for getting the template
// path   string
// url    string
// branch string
// sshkey string
// pull   bool // will pull if this is set
// reset  bool // this means will pull and reset all changes
// reload bool // reload the cache
//```
pub fn (mut site ZolaSite) content_add(args gittools.ReposGetArgs) ! {
	site.tree.scan(git_url: args.url, git_reset: args.reset, git_pull: args.pull, load: true)!
	mut gs := gittools.get()!
	mut repo := gs.get_repo(args)!
	mut repo_path := repo.get_path()!

	if os.exists('${repo_path}/content') {
		repo_path = '${repo_path}/content'
	}

	content_dest := '${site.path_build.path}/content'
	mut content_dir := pathlib.get_dir(path: content_dest)!
	os.cp_all('${repo_path}', content_dest, true)!
}

// add collections from doctree
//```args for getting the template
// path   string
// url    string
// branch string
// sshkey string
// pull   bool // will pull if this is set
// reset  bool // this means will pull and reset all changes
// reload bool // reload the cache
//```
pub fn (mut site ZolaSite) doctree_add(args gittools.ReposGetArgs) ! {
	site.tree.scan(git_url: args.url, git_reset: args.reset, git_pull: args.pull, load: args.reload)!
	doctree_dest := '${site.path_build.path}/doctree'
	mut doctree_dir := pathlib.get_dir(path: doctree_dest)!
	_ = doctree_dir.list(
		recursive: true
		regex: [r'.*\.md$']
		include_links: true
	)!
	site.tree.process_includes()!
}

pub fn (mut site ZolaSite) add_section(section_ Section) ! {
	section := Section{
		...section_
		name: texttools.name_fix(section_.name)
	}

	if section.name in site.sections {
		return error('Section with name `${section.name}` already exists.')
	}

	//  = 'section.html'
	site.sections[section.name] = section
}
