module doctree

import os
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.data.doctree.collection.data

const test_dir = '${os.dir(@FILE)}/testdata/process_defs_test'

fn test_process_defs() {
	/*
		1- use files with def actions and elements from testdata
		2- create tree
		3- invoke process defs
		4- check pages markdown
	*/
	mut tree := new(name: 'mynewtree')!
	tree.add_collection(path: '${test_dir}/col1', name: 'col1')!
	tree.add_collection(path: '${test_dir}/col2', name: 'col2')!
	tree.process_defs()!

	mut page1 := tree.page_get('col1:page1.md')!
	assert page1.get_markdown()! == ''

	mut page2 := tree.page_get('col2:page2.md')!
	assert page2.get_markdown()! == '[about us](col1:page1.md)\n[about us](col1:page1.md)\n[about us](col1:page1.md)'
}
