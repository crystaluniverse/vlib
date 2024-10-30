module doctree

import freeflowuniverse.crystallib.core.pathlib
import os

fn test_page_get() {
	mut file1_path := pathlib.get_file(path: '/tmp/mytree/dir1/file2.md', create: true)!
	file1_path.write('[some page](col2:file3.md)')!
	mut file2_path := pathlib.get_file(path: '/tmp/mytree/dir1/image.png', create: true)!
	mut file3_path := pathlib.get_file(path: '/tmp/mytree/dir1/dir2/file1.md', create: true)!
	file3_path.write('[not existent page](col3:file5.md)')!
	mut file4_path := pathlib.get_file(path: '/tmp/mytree/dir1/.collection', create: true)!
	file4_path.write('name:col1')!

	mut file5_path := pathlib.get_file(path: '/tmp/mytree/dir3/.collection', create: true)!
	file5_path.write('name:col2')!
	mut file6_path := pathlib.get_file(path: '/tmp/mytree/dir3/file3.md', create: true)!

	mut tree := new(name: 'mynewtree')!
	tree.add_collection(path: file1_path.parent()!.path, name: 'col1')!
	tree.add_collection(path: file6_path.parent()!.path, name: 'col2')!

	mut page := tree.page_get('col1:file2.md')!
	assert page.name == 'file2'

	mut image := tree.get_image('col1:image.png')!
	assert image.file_name() == 'image.png'

	// these page pointers are faulty

	apple_ptr_faulty0 := 'col3:file1.md'
	if p := tree.page_get('col3:file1.md') {
		assert false, 'this should fail: faulty pointer ${apple_ptr_faulty0}'
	}
}
