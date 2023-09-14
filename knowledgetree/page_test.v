module knowledgetree

import os
import freeflowuniverse.crystallib.markdowndocs
import freeflowuniverse.crystallib.pathlib

const testpath = os.dir(@FILE) + '/testdata/broken_chapter'

fn testsuite_end() {
	// reset testdata changes after running tests
	os.execute('git checkout ${knowledgetree.testpath}')
}

fn test_link_update() ! {}

fn test_fix_external_link() ! {}

fn test_fix() ! {
	mut tree := new()!
	mut test_collection := tree.collection_new(
		name: 'Collection1'
		path: knowledgetree.testpath
	) or { panic('Cannot create new collection: ${err}') }

	mut page_path := pathlib.get('${knowledgetree.testpath}/wrong_links/page_with_wrong_links.md')
	test_collection.page_new(mut page_path) or { panic('Cannot create page: ${err}') }
	mut test_page := test_collection.page_get('page_with_wrong_links.md')!

	doc_before := *((*test_page).doc)
	test_page.fix() or { panic('Cannot fix page: ${err}') }

	assert !test_page.changed // should be set to false after fix
	assert test_page.doc != doc_before // page was actually modified

	paragraph := test_page.doc.items[1] as markdowndocs.Paragraph
	wrong_link := paragraph.items[1] as markdowndocs.Link
	right_link := paragraph.items[3] as markdowndocs.Link

	// assert wrong_link.path :=
	// println(test_page.doc)
	// panic('s')
}

fn test_fix_links() ! {}

fn test_process_macro_include() {}

fn test_save() ! {}
