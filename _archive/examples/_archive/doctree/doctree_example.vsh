#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.data.markdownparser
import freeflowuniverse.crystallib.data.doctree
import freeflowuniverse.crystallib.web.mdbook
import freeflowuniverse.crystallib.core.base
import freeflowuniverse.crystallib.installers.web.mdbook as mdbookinstaller
import os

mdbookinstaller.install()!

console.print_header('Doc tree example.')
println('')

mut session := play.session_new(
	// context_name: "test"
	interactive: true
	// coderoot: "/tmp/code"
)!

// get path local to the current script
path_my_content := '${os.dir(@FILE)}/data'

mut tree := doctree.tree_create(name: 'test')!

// tree.scan(path: path_my_content)!
tree.scan(
	git_url: 'https://git.ourworld.tf/threefold_coop/info_threefold_coop/src/branch/main/collections'
)!
tree.export(dest: '/tmp/doctree_test', reset: true)!

// now generate an mdbook
mut mdbook_factory := mdbook.new(session: session)!
mut mybook := mdbook_factory.generate(
	doctree_path: '/tmp/doctree_test'
	name:         'mytestbook'
	title:        'My Title'
	summary_url:  'https://git.ourworld.tf/threefold_coop/info_threefold_coop/src/branch/main/books/duniayetu_dar'
)!

mybook.open()!
