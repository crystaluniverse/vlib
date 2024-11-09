#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import vfs
import os
import time

fn update_dir_children(mut dir vfs.Directory, name string, entry vfs.FSEntry) {
	// Update the children array by replacing the directory with the same name
	for i, child in dir.children {
		if child.metadata.name == name {
			dir.children[i] = entry
			return
		}
	}
}

fn main() {
	// Create new VFS instance with data directory
	data_dir := os.join_path(os.temp_dir(), 'vfs_test')
	mut fs := vfs.new(data_dir) or { panic(err) }
	mut root := fs.get_root()

	println('Creating directory structure...\n')

	// Create home directory
	mut home_dir := root.mkdir('home') or { panic(err) }
	println('Created home directory')
	
	// Create user1 directory in home
	mut user_dir := home_dir.mkdir('user1') or { panic(err) }
	update_dir_children(mut root, 'home', home_dir)
	println('Created user1 directory')
	
	// Create documents directory in user1
	mut docs_dir := user_dir.mkdir('documents') or { panic(err) }
	update_dir_children(mut home_dir, 'user1', user_dir)
	update_dir_children(mut root, 'home', home_dir)
	println('Created documents directory')

	// Create files using touch
	user_dir.touch('config.txt') or { panic(err) }
	docs_dir.touch('notes.md') or { panic(err) }
	docs_dir.touch('report.pdf') or { panic(err) }
	update_dir_children(mut user_dir, 'documents', docs_dir)
	update_dir_children(mut home_dir, 'user1', user_dir)
	update_dir_children(mut root, 'home', home_dir)
	println('Created files')

	// Write some content to files
	user_dir.write('config.txt', 'some configuration data\nport=8080\nhost=localhost') or { panic(err) }
	docs_dir.write('notes.md', '# My Notes\n\nThis is a test note.') or { panic(err) }
	docs_dir.write('report.pdf', 'Sample PDF content') or { panic(err) }
	update_dir_children(mut user_dir, 'documents', docs_dir)
	update_dir_children(mut home_dir, 'user1', user_dir)
	update_dir_children(mut root, 'home', home_dir)

	// Create a symlink
	mut symlink := vfs.Symlink{
		metadata: vfs.Metadata{
			id: u32(time.now().unix())
			name: 'latest_report'
			file_type: .symlink
			mode: 0o777
			owner: 'user'
			group: 'user'
		}
		parent_id: user_dir.metadata.id
		target: 'documents/report.pdf'
	}
	user_dir.children << symlink
	update_dir_children(mut home_dir, 'user1', user_dir)
	update_dir_children(mut root, 'home', home_dir)
	println('Added symlink')

	// Display directory structure
	println('\nDirectory structure:')
	println(root.printall(''))

	// Test rm functionality
	println('\nRemoving notes.md...')
	docs_dir.rm('notes.md') or { panic(err) }
	update_dir_children(mut user_dir, 'documents', docs_dir)
	update_dir_children(mut home_dir, 'user1', user_dir)
	update_dir_children(mut root, 'home', home_dir)

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
