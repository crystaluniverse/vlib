module doctree

import freeflowuniverse.crystallib.baobab.spawner
import freeflowuniverse.crystallib.data.markdownparser.elements
import os
import time

const (
	testdata_path     = os.dir(@FILE) + '/testdata'
	collections_path  = os.dir(@FILE) + '/testdata/collections'
	books_path        = os.dir(@FILE) + '/testdata/books'
	destinations_path = os.dir(@FILE) + '/testdata/destinations'
	tree_name         = 'mdbook_test_tree'
	book_source       = os.dir(@FILE) + '/testdata/book/source'
	book_destination  = os.dir(@FILE) + '/testdata/book/destination'

	test_books        = {
		'fruits_vegetables': TestBook{
			src_path: os.dir(@FILE) + '/testdata/books/fruits_vegetables/source/summary.md'
			dest_path: os.dir(@FILE) + '/testdata/books/fruits_vegetables/destination'
		}
	}
)

struct TestBook {
	src_path      string
	dest_path     string
	summary_items []string
}

fn testsuite_begin() {
	if os.exists(doctree.book_destination) {
		os.rmdir_all(doctree.book_destination)!
	}
	os.cp_all(doctree.testdata_path, '${doctree.testdata_path}_previous', true)!
}

fn testsuite_end() {
	os.rmdir_all(doctree.testdata_path)!
	os.mv('${doctree.testdata_path}_previous', doctree.testdata_path)!
}

fn test_book_generate() {
	mut tree := new()!
	tree.scan(
		path: doctree.collections_path
	)!

	for name, test_book in doctree.test_books {
		mut book := book_generate(
			name: name
			path: test_book.src_path
			dest: test_book.dest_path
			tree: tree
		)!
	}
}

fn test_book_reset() {
	mut tree := new()!
	tree.scan(
		path: doctree.collections_path
	)!

	for name, test_book in doctree.test_books {
		mut book := book_generate(
			name: 'book1'
			path: test_book.src_path
			dest: test_book.dest_path
			tree: tree
		)!

		assert os.exists(test_book.dest_path)
		book.reset()!
		assert !os.exists(test_book.dest_path)
	}
}

fn test_book_load_summary() {
	mut tree := new()!
	tree.scan(
		path: doctree.collections_path
	)!

	for name, test_book in doctree.test_books {
		mut book := book_generate(
			name: name
			path: test_book.src_path
			dest: test_book.dest_path
			tree: tree
		)!
		book.load_summary()!

		assert book.doc_summary.elements.len == 2
		assert book.doc_summary.elements[1] is elements.Paragraph
		toc_paragraph := book.doc_summary.elements[1] as elements.Paragraph
		// toc_links := toc_paragraph.elements.filter(it is elements.Link)
		// assert toc_links.len == 6
	}
}

fn test_book_fix_summary() {
	mut tree := new()!
	tree.scan(
		path: doctree.collections_path
	)!

	for name, test_book in doctree.test_books {
		mut book := book_generate(
			name: name
			path: test_book.src_path
			dest: test_book.dest_path
			tree: tree
		)!
		book.load_summary()!
		summary_links_before := '${book.doc_summary.elements}'
		book.fix_summary()!
		summary_links_after := '${book.doc_summary.elements}'
		assert summary_links_before != summary_links_after
	}
}

fn test_book_export() {
	mut tree := new()!
	tree.scan(
		path: doctree.collections_path
	)!

	for name, test_book in doctree.test_books {
		mut book := book_generate(
			name: name
			path: test_book.src_path
			dest: test_book.dest_path
			tree: tree
		)!
		book.export() or { panic(err) }
	}
}
