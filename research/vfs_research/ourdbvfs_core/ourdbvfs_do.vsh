#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.vfs.vfsourdb_core
import os
import time

fn main() {
	// Create data and metadata directories in temp
	base_dir := os.join_path(os.temp_dir(), 'vfs_test')
	data_dir := os.join_path(base_dir, 'data')
	metadata_dir := os.join_path(base_dir, 'metadata')

	// Create new VFS instance with proper database paths
	mut fs := vfsourdb_core.new(
		data_dir: data_dir
		metadata_dir: metadata_dir
	) or { panic(err) }

	mut root := fs.get_root() or { panic(err) }
	println('Creating directory structure...\n')

	// Create home directory
	mut home_dir := root.mkdir('home') or { panic(err) }
	println('Created home directory')
	
	// Create user1 directory in home
	mut user_dir := home_dir.mkdir('user1') or { panic(err) }
	println('Created user1 directory')
	
	// Create documents directory in user1
	mut docs_dir := user_dir.mkdir('documents') or { panic(err) }
	println('Created documents directory')

	// Create files using touch
	user_dir.touch('config.txt') or { panic(err) }
	docs_dir.touch('notes.md') or { panic(err) }
	docs_dir.touch('report.pdf') or { panic(err) }
	println('Created files')

	// Write some content to files
	user_dir.write('config.txt', 'some configuration data\nport=8080\nhost=localhost') or { panic(err) }
	docs_dir.write('notes.md', '# My Notes\n\nThis is a test note.') or { panic(err) }
	docs_dir.write('report.pdf', 'Sample PDF content') or { panic(err) }

	// Create a symlink
	mut symlink := vfsourdb_core.Symlink{
		metadata: vfsourdb_core.Metadata{
			id: u32(time.now().unix())
			name: 'latest_report'
			file_type: .symlink
			mode: 0o777
			owner: 'user'
			group: 'user'
		}
		target: 'documents/report.pdf'
	}
	user_dir.add_symlink(symlink) or { panic(err) }
	println('Added symlink')

	// Display directory structure
	println('\nDirectory structure:')
	println(root.printall(''))

	// Test rm functionality
	println('\nRemoving notes.md...')
	docs_dir.rm('notes.md') or { panic(err) }

	// Show updated structure
	println('\nUpdated directory structure:')
	println(root.printall(''))

	// Read config.txt content
	println('\nReading config.txt content:')
	config_content := user_dir.read('config.txt') or { panic(err) }
	println(config_content)

	// Save VFS state
	fs.save() or { panic(err) }
}
