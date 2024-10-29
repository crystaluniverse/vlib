module doctree

import freeflowuniverse.crystallib.core.pathlib

fn test_process_includes() {
	/*
		1- create 3 pages:
			- page1 includes page2
			- page2 includes page3
		2- create tree
		3- invoke process_includes
		4- check pages markdown
	*/

	mut page1_path := pathlib.get_file(path: '/tmp/col1/page1.md', create: true)!
	page1_content := "!!wiki.include page:'col2:page2.md'"
	page1_path.write(page1_content)!

	mut page2_path := pathlib.get_file(path: '/tmp/col2/page2.md', create: true)!
	page2_content := "!!wiki.include page:'col2:page3.md'"
	page2_path.write(page2_content)!

	mut page3_path := pathlib.get_file(path: '/tmp/col2/page3.md', create: true)!
	page3_content := 'page3 content'
	page3_path.write(page3_content)!

	mut tree := new(name: 'mynewtree')!
	tree.add_collection(path: page1_path.parent()!.path, name: 'col1')!
	tree.add_collection(path: page2_path.parent()!.path, name: 'col2')!
	tree.process_includes()!

	mut page1 := tree.page_get('col1:page1.md')!
	mut page2 := tree.page_get('col2:page2.md')!
	mut page3 := tree.page_get('col2:page3.md')!

	assert page1.get_markdown()! == 'page3 content'
	assert page2.get_markdown()! == 'page3 content'
	assert page3.get_markdown()! == 'page3 content'
}

fn test_generate_pages_graph() {
	/*
		1- create 3 pages:
			- page1 includes page2
			- page2 includes page3
		2- create tree
		3- invoke generate_pages_graph
		4- check graph
	*/

	mut page1_path := pathlib.get_file(path: '/tmp/col1/page1.md', create: true)!
	page1_content := "!!wiki.include page:'col2:page2.md'"
	page1_path.write(page1_content)!

	mut page2_path := pathlib.get_file(path: '/tmp/col2/page2.md', create: true)!
	page2_content := "!!wiki.include page:'col2:page3.md'"
	page2_path.write(page2_content)!

	mut page3_path := pathlib.get_file(path: '/tmp/col2/page3.md', create: true)!
	page3_content := 'page3 content'
	page3_path.write(page3_content)!

	mut tree := new(name: 'mynewtree')!
	tree.add_collection(path: page1_path.parent()!.path, name: 'col1')!
	tree.add_collection(path: page2_path.parent()!.path, name: 'col2')!
	mut page1 := tree.page_get('col1:page1.md')!
	mut page2 := tree.page_get('col2:page2.md')!
	mut page3 := tree.page_get('col2:page3.md')!

	graph := tree.generate_pages_graph()!
	assert graph == {
		'${page3.key()}': {
			'${page2.key()}': true
		}
		'${page2.key()}': {
			'${page1.key()}': true
		}
	}
}
