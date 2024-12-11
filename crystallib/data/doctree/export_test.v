module doctree

import freeflowuniverse.crystallib.core.pathlib
import os

const test_dir = '${os.dir(@FILE)}/testdata/export_test'
const tree_dir = '${test_dir}/mytree'
const export_dir = '${test_dir}/export'
const export_expected_dir = '${test_dir}/export_expected'

fn testsuite_begin() {
	pathlib.get_dir(
		path: export_dir
		empty: true
	)!
}

fn testsuite_end() {
	pathlib.get_dir(
		path: export_dir
		empty: true
	)!
}

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

	mut tree := new(name: 'mynewtree')!
	tree.add_collection(path: '${tree_dir}/dir1', name: 'col1')!
	tree.add_collection(path: '${tree_dir}/dir3', name: 'col2')!

	tree.export(destination: '${export_dir}')!

	col1_path := '${export_dir}/col1'
	expected_col1_path := '${export_expected_dir}/col1'
	assert os.read_file('${col1_path}/.collection')! == os.read_file('${expected_col1_path}/.collection')!
	assert os.read_file('${col1_path}/.linkedpages')! == os.read_file('${expected_col1_path}/.linkedpages')!
	assert os.read_file('${col1_path}/errors.md')! == os.read_file('${expected_col1_path}/errors.md')!
	assert os.read_file('${col1_path}/file1.md')! == os.read_file('${expected_col1_path}/file1.md')!
	assert os.read_file('${col1_path}/file2.md')! == os.read_file('${expected_col1_path}/file2.md')!

	col2_path := '${export_dir}/col2'
	expected_col2_path := '${export_expected_dir}/col2'
	assert os.read_file('${col2_path}/.linkedpages')! == ''
	assert os.read_file('${col2_path}/.collection')! == os.read_file('${expected_col2_path}/.collection')!
	assert os.read_file('${col2_path}/file3.md')! == ''
}
