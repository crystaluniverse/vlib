module collection

import freeflowuniverse.crystallib.core.pathlib
import os

const test_dir = '${os.dir(@FILE)}/testdata/export_test'
const tree_dir = '${test_dir}/mytree'
const export_dir = '${test_dir}/export'
const export_expected_dir = '${test_dir}/export_expected'

fn testsuite_begin() {
	pathlib.get_dir(
		path:  export_dir
		empty: true
	)!
}

fn testsuite_end() {
	pathlib.get_dir(
		path:  export_dir
		empty: true
	)!
}

fn test_export() {
	mut col := Collection{
		name: 'col1'
		path: pathlib.get('${tree_dir}/dir1')
	}
	col.scan()!

	path_dest := pathlib.get_dir(path: '${export_dir}/src', create: true)!
	col.export(
		destination: path_dest
		file_paths:  {
			'col2:file3.md': 'col2/file3.md'
		}
	)!

	col1_path := '${export_dir}/src/col1'
	expected_col1_path := '${export_expected_dir}/src/col1'
	assert os.read_file('${col1_path}/.collection')! == os.read_file('${expected_col1_path}/.collection')!
	assert os.read_file('${col1_path}/.linkedpages')! == os.read_file('${expected_col1_path}/.linkedpages')!
	assert os.read_file('${col1_path}/errors.md')! == os.read_file('${expected_col1_path}/errors.md')!
	assert os.read_file('${col1_path}/file1.md')! == os.read_file('${expected_col1_path}/file1.md')!
	assert os.read_file('${col1_path}/file2.md')! == os.read_file('${expected_col1_path}/file2.md')!
}
