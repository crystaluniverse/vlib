module collection

import freeflowuniverse.crystallib.core.pathlib
import os

fn test_export() {
	mut file1_path := pathlib.get_file(path: '/tmp/mytree/dir1/file2.md', create: true)!
	file1_path.write('[some page](col2:file3.md)')!
	mut file2_path := pathlib.get_file(path: '/tmp/mytree/dir1/image.png', create: true)!
	mut file3_path := pathlib.get_file(path: '/tmp/mytree/dir1/dir2/file1.md', create: true)!
	file3_path.write('[not existent page](col3:file5.md)')!
	mut file4_path := pathlib.get_file(path: '/tmp/mytree/dir1/.collection', create: true)!
	file4_path.write('name:col1')!

	mut col := Collection{
		name: 'col1'
		path: pathlib.get('/tmp/mytree/dir1')
	}
	col.scan()!

	path_src := pathlib.get_dir(path: '/tmp/export_test/src', create: true)!
	path_edit := pathlib.get_dir(path: '/tmp/export_test/.edit', create: true)!
	col.export(
		path_src: path_src
		path_edit: path_edit
		file_paths: {
			'col2:file3.md': 'col2/file3.md'
		}
	)!

	defer {
		os.rmdir_all('/tmp/export_test') or {}
		os.rmdir_all('/tmp/mytree') or {}
	}

	col1_path := '/tmp/export_test/src/col1'
	assert os.read_file('${col1_path}/.collection')! == "name:col1 src:'/tmp/mytree/dir1'"
	assert os.read_file('${col1_path}/.linkedpages')! == 'col2:file3.md'
	assert os.read_file('${col1_path}/errors.md')! == '# Errors\n\n\n\n## unknown \n\nlinked item col3:file5.md not found\n\n'
	assert os.read_file('${col1_path}/file1.md')! == '[not existent page](col3:file5.md)'
	assert os.read_file('${col1_path}/file2.md')! == '[some page](../col2/file3.md)'
}
