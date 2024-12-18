module vfscore

import os

fn test_vfs_implementations() ! {
	// Test local vfscore
	mut local_vfs := new_local_vfs('/tmp/test_local_vfs')!
	local_vfs.destroy()!

	// Create and write to a file
	local_vfs.file_create('test.txt')!
	local_vfs.file_write('test.txt', 'Hello, World!'.bytes())!

	// Read the file
	content := local_vfs.file_read('test.txt')!
	assert content.bytestr() == 'Hello, World!'

	// Create a directory and list its contents
	local_vfs.dir_create('subdir')!
	local_vfs.file_create('subdir/file1.txt')!
	local_vfs.file_write('subdir/file1.txt', 'File 1'.bytes())!
	local_vfs.file_create('subdir/file2.txt')!
	local_vfs.file_write('subdir/file2.txt', 'File 2'.bytes())!

	entries := local_vfs.dir_list('subdir')!
	assert entries.len == 2

	// Test entry operations
	assert local_vfs.exists('test.txt')
	entry := local_vfs.get('test.txt')!
	assert entry.get_metadata().name == 'test.txt'

	// Test rename and copy
	local_vfs.rename('test.txt', 'test2.txt')!
	local_vfs.copy('test2.txt', 'test3.txt')!

	// Verify test2.txt exists before creating symlink
	if !local_vfs.exists('test2.txt') {
		panic('test2.txt does not exist before symlink creation')
	}

	// Create and read symlink using relative paths
	local_vfs.link_create('test2.txt', 'test_link.txt')!

	// Verify symlink was created
	if !local_vfs.exists('test_link.txt') {
		panic('test_link.txt was not created')
	}

	// Read the symlink
	link_target := local_vfs.link_read('test_link.txt')!
	target_base := os.base(link_target)
	if target_base != 'test2.txt' {
		eprintln('Expected link target: test2.txt')
		eprintln('Actual link target: ${target_base}')
		panic('Symlink points to wrong target')
	}

	// Cleanup
	local_vfs.delete('test2.txt')!
	local_vfs.delete('subdir')!
	local_vfs.delete('test_link.txt')!

	os.rmdir('/tmp/test_local_vfs') or {}
}
