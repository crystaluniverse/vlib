module doctree

import os
import freeflowuniverse.crystallib.core.pathlib

const test_dir = '${os.dir(@FILE)}/testdata/process_includes_test'

fn test_process_includes() {
	/*
		1- use 3 pages in testdata:
			- page1 includes page2
			- page2 includes page3
		2- create tree
		3- invoke process_includes
		4- check pages markdown
	*/
	mut tree := new(name: 'mynewtree')!
	tree.add_collection(path: '${test_dir}/col1', name: 'col1')!
	tree.add_collection(path: '${test_dir}/col2', name: 'col2')!
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
		1- use 3 pages in testdata:
			- page1 includes page2
			- page2 includes page3
		2- create tree
		3- invoke generate_pages_graph
		4- check graph
	*/
	mut tree := new(name: 'mynewtree')!
	tree.add_collection(path: '${test_dir}/col1', name: 'col1')!
	tree.add_collection(path: '${test_dir}/col2', name: 'col2')!
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
