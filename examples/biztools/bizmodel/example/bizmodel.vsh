#!/usr/bin/env -S v -cg -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run
//#!/usr/bin/env -S v -cg -enable-globals run

import freeflowuniverse.crystallib.data.doctree
import freeflowuniverse.crystallib.biz.bizmodel
import freeflowuniverse.crystallib.core.playbook
import freeflowuniverse.crystallib.core.playcmds
import freeflowuniverse.crystallib.web.mdbook
import os


const wikipath = os.dir(@FILE) + '/wiki'
const summarypath = os.dir(@FILE) + '/wiki/summary.md'

//execute the actions so we have the info populated
// mut plb:=playbook.new(path: wikipath)!
// playcmds.run(mut plb,false)!

buildpath:="${os.home_dir()}/hero/var/mdbuild/bizmodel"

// just run the doctree & mdbook and it should
// load the doctree, these are all collections
mut tree := doctree.new(name: 'bizmodel')!
tree.scan(path: wikipath)!
tree.export(dest: buildpath, reset: true)!

// mut bm:=bizmodel.get("test")!
// println(bm)

mut mdbooks := mdbook.get()!
mdbooks.generate(
	name:"bizmodel"
	summary_path: summarypath
	doctree_path: buildpath
	title:        "bizmodel example"
)!
mdbook.book_open("bizmodel")!


