#!/usr/bin/env -S v -enable-globals run

import freeflowuniverse.crystallib.data.doctree
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.web.mdbook
import os


// directory of collections used in the example
const example_dir = os.join_path(os.home_dir(), 'code/github/freeflowuniverse/crystallib/crystallib/data/doctree/testdata/tree_test')

// create tree and scan collection dir
mut tree := doctree.new(name: 'example_mdbook')!
tree.scan(path: example_dir)!

// check collections scanned as expected
assert tree.collections.len == 2
assert tree.collections.keys() == ['fruits', 'test_vegetables']

example_dest := '${os.dir(@FILE)}/destination'

// export tree
tree.export(destination: '${example_dest}/tree', reset: true)!

mut mdb := mdbook.get()!

mut summary_path := pathlib.get_file(path: '${example_dest}/SUMMARY.md', create: true)!
summar_content := '
- [Page number 1](fruits/apple.md)
- [fruit intro](fruits/intro.md)
- [rpc page](rpc/tfchain.md)
- [vegies](test_vegetables/tomato.md)
'
summary_path.write(summar_content)!

// generate mdbook from summary and exported collections
mut b:=mdb.generate(
	name: 'mdbook_example'
	title: 'MDBook Example'
	summary_path: summary_path.path
	publish_path: '${example_dest}/publish'
	build_path: '${example_dest}/build'
	export: true
	collections: [
		'${example_dest}/tree/fruits'
		'${example_dest}/tree/test_vegetables'
	]
)!

b.open()!