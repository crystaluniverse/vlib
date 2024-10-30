module doctree

import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.data.doctree.collection.data
import freeflowuniverse.crystallib.data.doctree.collection
import os

const collections_path = os.dir(@FILE) + '/testdata'
const tree_name = 'tree_test_tree'

fn test_write_tree() {
	write_dir1 := pathlib.get_dir(path: '/tmp/tree_write1', empty: true)!
	write_dir2 := pathlib.get_dir(path: '/tmp/tree_write2', empty: true)!
	write_dir3 := pathlib.get_dir(path: '/tmp/tree_write3', empty: true)!

	// read tree1
	mut tree1 := new(name: doctree.tree_name)!
	tree1.scan(path: doctree.collections_path)!
	tree1.export(destination: write_dir1.path)!

	// create tree2 from the written tree
	mut tree2 := new(name: doctree.tree_name)!
	tree2.scan(path: write_dir1.path)!
	tree2.export(destination: write_dir2.path)!

	// write tree2 another time to compare the output of the two
	mut tree3 := new(name: doctree.tree_name)!
	tree3.scan(path: write_dir2.path)!
	tree3.export(destination: write_dir3.path)!

	// assert the 1e tree matches the third one
	assert tree1.collections.len == tree3.collections.len
	for k, mut col1 in tree1.collections {
		mut col3 := tree3.collections[k] or { panic('collection ${k} is not in tree copy') }
		match_collections(mut *col1, mut *col3)!
	}

	// assert the 2nd tree matches the third one
	assert tree2.collections.len == tree3.collections.len
	for k, mut col2 in tree2.collections {
		mut col3 := tree3.collections[k] or { panic('collection ${k} is not in tree copy') }
		match_collections(mut *col2, mut *col3)!
	}
}

fn match_files(mut files1 map[string]&data.File, mut files2 map[string]&data.File) ! {
	assert files1.len == files2.len
	for name, mut file1 in files1 {
		mut file2 := files2[name] or { return error("${name} doesn't exist in both collections") }
		file1_cont := file1.path.read()!
		file2_cont := file2.path.read()!
		if file1_cont != file2_cont {
			return error('${name} content mismatch')
		}
	}
}

fn match_pages(mut pages1 map[string]&data.Page, mut pages2 map[string]&data.Page) ! {
	// errors are added so not same as original
	if 'errors' in pages1.keys() {
		pages1.delete('errors')
	}
	if 'errors' in pages2.keys() {
		pages2.delete('errors')
	}
	if pages1.len != pages2.len {
		return error('nr of pages does not correspond in both collection')
	}
	for name, mut page1 in pages1 {
		mut page2 := pages2[name] or { return error("${name} doesn't exist in both collections") }
		assert page1.get_markdown()!.trim_space() == page2.get_markdown()!.trim_space()
	}
}

fn match_collections(mut col1 collection.Collection, mut col2 collection.Collection) ! {
	match_files(mut col1.files, mut col2.files)!
	match_files(mut col1.images, mut col2.images)!
	match_pages(mut col1.pages, mut col2.pages)!
}
