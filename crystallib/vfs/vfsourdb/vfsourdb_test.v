module vfsourdb

import os

fn test_vfsourdb() ! {
	println('Testing OurDB VFS...')

	// Create test directories
	test_data_dir := os.join_path(os.temp_dir(), 'vfsourdb_test_data')
	test_meta_dir := os.join_path(os.temp_dir(), 'vfsourdb_test_meta')

	os.mkdir_all(test_data_dir)!
	os.mkdir_all(test_meta_dir)!

	defer {
		os.rmdir_all(test_data_dir) or {}
		os.rmdir_all(test_meta_dir) or {}
	}

	// Create VFS instance
	mut vfs := new(test_data_dir, test_meta_dir)!

	// Test root directory
	mut root := vfs.root_get()!
	assert root.get_metadata().file_type == .directory
	assert root.get_metadata().name == ''

	// Test directory creation
	mut test_dir := vfs.dir_create('/test_dir')!
	assert test_dir.get_metadata().name == 'test_dir'
	assert test_dir.get_metadata().file_type == .directory

	// Test file creation and writing
	mut test_file := vfs.file_create('/test_dir/test.txt')!
	assert test_file.get_metadata().name == 'test.txt'
	assert test_file.get_metadata().file_type == .file

	test_content := 'Hello, World!'.bytes()
	vfs.file_write('/test_dir/test.txt', test_content)!

	// Test file reading
	read_content := vfs.file_read('/test_dir/test.txt')!
	assert read_content == test_content

	// Test directory listing
	entries := vfs.dir_list('/test_dir')!
	assert entries.len == 1
	assert entries[0].get_metadata().name == 'test.txt'

	// Test exists
	assert vfs.exists('/test_dir')! == true
	assert vfs.exists('/test_dir/test.txt')! == true
	assert vfs.exists('/nonexistent')! == false

	// Test symlink creation and reading
	vfs.link_create('/test_dir/test.txt', '/test_dir/test_link')!
	link_target := vfs.link_read('/test_dir/test_link')!
	assert link_target == '/test_dir/test.txt'

	// Test file deletion
	vfs.file_delete('/test_dir/test.txt')!
	assert vfs.exists('/test_dir/test.txt')! == false

	// Test directory deletion
	vfs.dir_delete('/test_dir')!
	assert vfs.exists('/test_dir')! == false

	println('Test completed successfully!')
}
