module vfsnested

import os

fn test_nested() ! {
	println('Testing Nested VFS...')

	// Create root directories for test VFS instances
	os.mkdir_all('/tmp/test_nested_vfs/vfs1') or { panic(err) }
	os.mkdir_all('/tmp/test_nested_vfs/vfs2') or { panic(err) }
	os.mkdir_all('/tmp/test_nested_vfs/vfs3') or { panic(err) }

	// Create VFS instances
	mut vfs1 := vfscore.new_local_vfs('/tmp/test_nested_vfs/vfs1') or { panic(err) }
	mut vfs2 := vfscore.new_local_vfs('/tmp/test_nested_vfs/vfs2') or { panic(err) }
	mut vfs3 := vfscore.new_local_vfs('/tmp/test_nested_vfs/vfs3') or { panic(err) }

	// Create nested VFS
	mut nested_vfs := new()

	// Add VFS instances at different paths
	nested_vfs.add_vfs('/data', vfs1) or { panic(err) }
	nested_vfs.add_vfs('/config', vfs2) or { panic(err) }
	nested_vfs.add_vfs('/data/backup', vfs3) or { panic(err) } // Nested under /data

	println('\nTesting file operations...')

	// Create and write to files in different VFS instances
	nested_vfs.file_create('/data/test.txt') or { panic(err) }
	nested_vfs.file_write('/data/test.txt', 'Hello from VFS1'.bytes()) or { panic(err) }

	nested_vfs.file_create('/config/settings.txt') or { panic(err) }
	nested_vfs.file_write('/config/settings.txt', 'Hello from VFS2'.bytes()) or { panic(err) }

	nested_vfs.file_create('/data/backup/archive.txt') or { panic(err) }
	nested_vfs.file_write('/data/backup/archive.txt', 'Hello from VFS3'.bytes()) or { panic(err) }

	// Read and verify file contents
	data1 := nested_vfs.file_read('/data/test.txt') or { panic(err) }
	println('Content from /data/test.txt: ${data1.bytestr()}')

	data2 := nested_vfs.file_read('/config/settings.txt') or { panic(err) }
	println('Content from /config/settings.txt: ${data2.bytestr()}')

	data3 := nested_vfs.file_read('/data/backup/archive.txt') or { panic(err) }
	println('Content from /data/backup/archive.txt: ${data3.bytestr()}')

	println('\nTesting directory operations...')

	// List root directory
	println('Root directory contents:')
	root_entries := nested_vfs.dir_list('/') or { panic(err) }
	for entry in root_entries {
		meta := entry.get_metadata()
		println('- ${meta.name} (${meta.file_type})')
	}

	// Create and list directories
	nested_vfs.dir_create('/data/subdir') or { panic(err) }
	nested_vfs.file_create('/data/subdir/file.txt') or { panic(err) }
	nested_vfs.file_write('/data/subdir/file.txt', 'Nested file content'.bytes()) or { panic(err) }

	println('\nListing /data directory:')
	data_entries := nested_vfs.dir_list('/data') or { panic(err) }
	for entry in data_entries {
		meta := entry.get_metadata()
		println('- ${meta.name} (${meta.file_type})')
	}

	println('\nTesting cross-VFS operations...')

	// Copy file between different VFS instances
	nested_vfs.copy('/data/test.txt', '/config/test_copy.txt') or { panic(err) }
	copy_data := nested_vfs.file_read('/config/test_copy.txt') or { panic(err) }
	println('Copied file content: ${copy_data.bytestr()}')

	println('\nCleanup...')

	// Cleanup
	nested_vfs.destroy() or { panic(err) }
	os.rmdir_all('/tmp/test_nested_vfs') or { panic(err) }

	println('Test completed successfully!')
}
