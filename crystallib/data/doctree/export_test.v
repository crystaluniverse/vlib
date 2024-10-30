module doctree

import freeflowuniverse.crystallib.core.pathlib
import os

fn test_export() {
	/*
		tree_root/
			dir1/
				.collection
				dir2/
					file1.md
				file2.md
				image.png
			dir3/
				.collection
				file3.md

		export:
			export_dest/
				src/
					col1/
						.collection
						.linkedpages
						errors.md
						img/
							image.png
						file1.md
						file2.md
					col2/
						.collection
						.linkedpages
						file3.md

				.edit/

		test:
			- create tree
			- add files/pages and collections to tree
			- export tree
			- ensure tree structure is valid
	*/

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

	tree.export(dest: '/tmp/export_test')!

	defer {
		os.rmdir_all('/tmp/export_test') or {}
		os.rmdir_all('/tmp/mytree') or {}
	}

	col1_path := '/tmp/export_test/src/col1'
	assert os.read_file('${col1_path}/.linkedpages')! == 'col2:file3.md'
	assert os.read_file('${col1_path}/.collection')! == "name:col1 src:'/tmp/mytree/dir1'"
	assert os.read_file('${col1_path}/errors.md')! == '# Errors\n\n\n\n## unknown \n\nlinked item col3:file5.md not found\n\n'
	assert os.read_file('${col1_path}/file1.md')! == '[not existent page](col3:file5.md)'
	assert os.read_file('${col1_path}/file2.md')! == '[some page](../col2/file3.md)'

	col2_path := '/tmp/export_test/src/col2'
	assert os.read_file('${col2_path}/.linkedpages')! == ''
	assert os.read_file('${col2_path}/.collection')! == "name:col2 src:'/tmp/mytree/dir3'"
	assert os.read_file('${col2_path}/file3.md')! == ''
}
