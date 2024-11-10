#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import os
import freeflowuniverse.crystallib.data.encoder
import vfs

fn test_encode_decode() ! {
	println('Starting encode/decode test...')

	// Create temporary directories for VFS
	temp_dir := os.temp_dir()
	data_dir := os.join_path(temp_dir, 'vfs_test_data')
	meta_dir := os.join_path(temp_dir, 'vfs_test_meta')

	// Cleanup any existing test directories
	os.rmdir_all(data_dir) or {}
	os.rmdir_all(meta_dir) or {}

	// Initialize VFS
	mut fs := vfs.new(
		data_dir: data_dir
		metadata_dir: meta_dir
	)!
	
	// Get root directory
	mut root := fs.get_root()!
	println('Created root directory')

	// Create test file using primitive operations
	mut file := root.touch('test.txt')!
	file.write('Hello, World!')!
	println('Added test file')

	// Create symlink
	mut symlink := vfs.Symlink{
		metadata: vfs.Metadata{
			id: 3
			name: 'link'
			file_type: .symlink
			mode: 0o777
			owner: 'test'
			group: 'test'
		}
		parent_id: root.metadata.id
		target: '/target/path'
		myvfs: fs
	}
	root.add_symlink(symlink)!
	println('Added symlink')

	// Create subdirectory with file using primitives
	mut subdir := root.mkdir('subdir')!
	mut subfile := subdir.touch('subfile.txt')!
	subfile.write('Nested file content')!
	println('Added subdirectory with nested file')

	println('\nOriginal structure:')
	println(root.printall('')!)

	// Encode the directory structure
	encoded := root.encode()
	println('\nEncoded size: ${encoded.len} bytes')

	// Save encoded data to file for debugging
	os.write_file('encoded.bin', encoded.bytestr()) or {
		println('Failed to write encoded data: ${err}')
		return err
	}
	println('Saved encoded data to encoded.bin')

	// Decode back to directory
	println('\nDecoding data...')
	mut decoded := vfs.decode_directory(encoded) or {
		println('Failed to decode: ${err}')
		return err
	}
	println('Successfully decoded data')

	println('\nDecoded structure:')
	println(decoded.printall('')!)

	// Verify structure matches
	assert decoded.metadata.id == root.metadata.id
	assert decoded.metadata.name == root.metadata.name
	assert decoded.children.len == root.children.len
	println('\nBasic structure verification passed')

	// Verify file content
	file_content := root.read('test.txt')!
	assert file_content == 'Hello, World!'
	println('File content verification passed')

	// Verify symlink
	mut children := root.children(false)!
	for child in children {
		if child is vfs.Symlink {
			assert child.target == '/target/path'
			println('Symlink verification passed')
			break
		}
	}

	// Verify subdirectory content
	subdir_content := subdir.read('subfile.txt')!
	assert subdir_content == 'Nested file content'
	println('Subdirectory content verification passed')

	// Final cleanup
	os.rmdir_all(data_dir) or {}
	os.rmdir_all(meta_dir) or {}

	println('\nAll tests passed successfully!')
}

fn main() {
	test_encode_decode() or { eprintln('Error: ${err}') }
}
