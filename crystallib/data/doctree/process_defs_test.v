module doctree

import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.data.doctree.collection.data

fn test_process_defs() {
	/*
		1- create files with def actions and elements
		2- create tree
		3- invoke process defs
		4- check pages markdown
	*/

	mut page1_path := pathlib.get_file(path: '/tmp/col1/page1.md', create: true)!
	page1_content := "!!wiki.def alias:'tf-dev,cloud-dev,threefold-dev' name:'about us'"
	page1_path.write(page1_content)!

	mut page2_path := pathlib.get_file(path: '/tmp/col2/page2.md', create: true)!
	page2_content := '*TFDEV\n*CLOUDDEV\n*THREEFOLDDEV'
	page2_path.write(page2_content)!

	mut tree := new(name: 'mynewtree')!
	tree.add_collection(path: page1_path.parent()!.path, name: 'col1')!
	tree.add_collection(path: page2_path.parent()!.path, name: 'col2')!
	tree.process_defs()!

	mut page1 := tree.page_get('col1:page1.md')!
	assert page1.get_markdown()! == ''

	mut page2 := tree.page_get('col2:page2.md')!
	assert page2.get_markdown()! == '[about us](col1:page1.md)\n[about us](col1:page1.md)\n[about us](col1:page1.md)'
}
