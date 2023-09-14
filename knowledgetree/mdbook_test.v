module knowledgetree

import os

const collections_path = os.dir(@FILE) + '/testdata/collections'

const book1_path = os.dir(@FILE) + '/testdata/book1'

fn test_book_new() {
	mut tree := new()!

	mut col_examples := tree.collection_new(
		name: 'examples'
		path: knowledgetree.collections_path + '/examples'
		heal: true
	)!
	mut col_playground := tree.collection_new(
		name: 'playground'
		path: knowledgetree.collections_path + '/playground'
		heal: true
	)!
	mut col_rpc := tree.collection_new(
		name: 'rpc'
		path: knowledgetree.collections_path + '/rpc'
		heal: true
	)!
	mut col_server := tree.collection_new(
		name: 'server'
		path: knowledgetree.collections_path + '/server'
		heal: true
	)!

	mut book := tree.book_new(name: 'book1', path: knowledgetree.book1_path, dest: '_book1')!
	book.export()!
}
