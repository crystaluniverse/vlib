#!/usr/bin/env -S v -enable-globals run

import freeflowuniverse.crystallib.data.doctree
import os

const test_dir = os.join_path(os.home_dir(), 'code/github/freeflowuniverse/crystallib/crystallib/data/doctree/testdata/process_includes_test')

/*
	1- use 3 pages in testdata:
		- page1 includes page2
		- page2 includes page3
	2- create tree
	3- invoke process_includes
	4- check pages markdown
*/
mut tree := doctree.new(name: 'example')!
tree.scan(path: test_dir)!
tree.process_includes()!

mut page1 := tree.page_get('col1:page1.md')!
mut page2 := tree.page_get('col2:page2.md')!
mut page3 := tree.page_get('col2:page3.md')!

assert page1.get_markdown() or {''} == 'page3 content'
assert page2.get_markdown() or {''} == 'page3 content'
assert page3.get_markdown() or {''} == 'page3 content'